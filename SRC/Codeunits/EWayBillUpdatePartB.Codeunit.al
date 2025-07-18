namespace LFSEWayBillModule.LFSEWayBillModule;
using Microsoft.Sales.History;
using Microsoft.Inventory.Transfer;
using Microsoft.Finance.GST.Base;
using Microsoft.Inventory.Location;
using Microsoft.Finance.TaxBase;

codeunit 73101 "LFS E-Way Bill Update Part-B"
{
    Permissions = tabledata "Sales Invoice Header" = RM, tabledata "Transfer Shipment Header" = RM;

    var
        GlbTextVars: Text;

    procedure UpdatePartBEWAYBILL(GlbTextVar: Text; GSTRegistrationNo: Code[20]; DocumentNo: Code[20])
    var
        GSTRegNos: Record "GST Registration Nos.";
        PostedSalesInvoice: Record "Sales Invoice Header";
        PostedTransferShipment: Record "Transfer Shipment Header";
        PostedSalesCreditMemo: Record "Sales Cr.Memo Header";
        Remarks: Text;
        Status: Text;
#pragma warning disable AA0470
        ReturnMsg: Label 'Status : %1\ %2';
#pragma warning restore AA0470
        HHTPClient: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpHeader: HttpHeaders;
        HttpContent: HttpContent;
        Response: Text;
        JSONObject: JsonObject;
        JSONToken: JsonToken;
        ValueJSONToken: JsonToken;
        JSONValue: JsonValue;
        JSONArray: JsonArray;
        i: Integer;
        OutStream: OutStream;
    begin
        GSTRegNos.Reset();
        GSTRegNos.Get(GSTRegistrationNo);
        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(GSTRegNos."LFS E-Way Bill API URL");
        HttpContent.WriteFrom(GlbTextVar);
        HttpContent.GetHeaders(HttpHeader);
        HttpHeader.Add('PRIVATEKEY', GSTRegNos."LFS E-Way Bill PrivateKey");
        HttpHeader.Add('PRIVATEVALUE', GSTRegNos."LFS E-Way Bill PrivateValue");
        HttpHeader.Add('IP', GSTRegNos."LFS E-Way Bill IP Address");
        HttpHeader.Remove('Content-Type');
        HttpHeader.Add('Content-Type', 'application/json');
        HttpRequest.Content(HttpContent);
        if HHTPClient.Send(HttpRequest, HttpResponse) then begin
            if HttpResponse.HttpStatusCode() = 200 then begin
                HttpResponse.Content.ReadAs(Response);
                Message(Response);
                if JSONToken.ReadFrom(Response) then
                    if JSONToken.IsObject then begin
                        JSONObject := JSONToken.AsObject();
                        JSONObject.Get('MessageId', valueJSONToken);
                        if valueJSONToken.AsValue().AsText() = '1' then
                            if JSONObject.Get('Data', JSONToken) then
                                if JSONToken.IsArray then begin
                                    JSONArray.ReadFrom(format(JSONToken));
                                    for i := 0 to JSONArray.Count() - 1 do begin
                                        JSONArray.Get(i, JSONToken);
                                        JSONObject := JSONToken.AsObject();
                                        // JSONObject.Get('STATUS', JSONToken);
                                        // Status := JSONToken.AsValue().AsText();
                                        if JSONObject.Get('Remarks', JSONToken) then begin
                                            if JSONToken.IsValue() then begin
                                                JSONValue := JSONToken.AsValue();

                                                if not JSONValue.IsNull() then
                                                    Evaluate(Remarks, JSONValue.AsText())
                                                else
                                                    Remarks := '';
                                            end else
                                                Remarks := ''; // Not a value type
                                        end else
                                            Remarks := ''; // Key doesn't exist
                                        if JSONObject.Get('Status', valueJSONToken) then begin
                                            if valueJSONToken.IsValue then begin
                                                JSONValue := valueJSONToken.AsValue();
                                                if not JSONValue.IsNull() then
                                                    Evaluate(Status, JSONValue.AsText())
                                                else
                                                    Status := '';
                                            end else
                                                Status := '';
                                        end else
                                            Status := '';

                                        if Status = 'FAILED' then
                                            Error('Status : %1\ %2', Remarks, Status);

                                        if DocumentNo <> '' then begin
                                            PostedSalesInvoice.Reset();
                                            PostedSalesInvoice.SetRange("No.", DocumentNo);
                                            if PostedSalesInvoice.FindFirst() then begin
                                                JSONObject.Get('EwbNo', valueJSONToken);
                                                JSONObject.Get('ValidUptoDate', valueJSONToken);
                                                PostedSalesInvoice."LFS E-Way Bill Valid Upto Date" := CopyStr(valueJSONToken.AsValue().AsText(), 1, MaxStrLen(PostedSalesInvoice."LFS E-Way Bill Valid Upto Date"));
                                                JSONObject.Get('VechileUpdateDate', valueJSONToken);
                                                PostedSalesInvoice."LFS E-Way Bill VehicleUpdtDate" := CopyStr(valueJSONToken.AsValue().AsText(), 1, MaxStrLen(PostedSalesInvoice."LFS E-Way Bill VehicleUpdtDate"));
                                                PostedSalesInvoice."LFS E-Way Bill Message".CreateOutStream(OutStream);
                                                OutStream.WriteText(StrSubstNo(ReturnMsg, Remarks, Status));
                                                PostedSalesInvoice.Modify();
                                            end;
                                            //Update Posted Sales Credit Memo
                                            PostedSalesCreditMemo.Reset();
                                            PostedSalesCreditMemo.SetRange("No.", DocumentNo);
                                            if PostedSalesCreditMemo.FindFirst() then begin
                                                JSONObject.Get('EwbNo', valueJSONToken);
                                                JSONObject.Get('ValidUptoDate', valueJSONToken);
                                                PostedSalesCreditMemo."LFS E-Way Bill Valid Upto Date" := CopyStr(valueJSONToken.AsValue().AsText(), 1, MaxStrLen(PostedSalesCreditMemo."LFS E-Way Bill Valid Upto Date"));
                                                JSONObject.Get('VechileUpdateDate', valueJSONToken);
                                                PostedSalesCreditMemo."LFS E-Way Bill VehicleUpdtDate" := CopyStr(valueJSONToken.AsValue().AsText(), 1, MaxStrLen(PostedSalesCreditMemo."LFS E-Way Bill VehicleUpdtDate"));
                                                PostedSalesCreditMemo."LFS E-Way Bill Message".CreateOutStream(OutStream);
                                                OutStream.WriteText(StrSubstNo(ReturnMsg, Remarks, Status));
                                                PostedSalesCreditMemo.Modify();
                                            end;
                                            // Update Posted Transfer Shipment
                                            PostedTransferShipment.Reset();
                                            PostedTransferShipment.SetRange("No.", DocumentNo);
                                            if PostedTransferShipment.FindFirst() then begin
                                                JSONObject.Get('EwbNo', valueJSONToken);
                                                JSONObject.Get('ValidUptoDate', valueJSONToken);
                                                PostedTransferShipment."LFS E-Way Bill Valid Upto Date" := CopyStr(valueJSONToken.AsValue().AsText(), 1, MaxStrLen(PostedTransferShipment."LFS E-Way Bill Valid Upto Date"));
                                                JSONObject.Get('VechileUpdateDate', valueJSONToken);
                                                PostedTransferShipment."LFS E-Way Bill VehicleUpdtDate" := CopyStr(valueJSONToken.AsValue().AsText(), 1, MaxStrLen(PostedTransferShipment."LFS E-Way Bill VehicleUpdtDate"));
                                                PostedTransferShipment."LFS E-Way Bill Message".CreateOutStream(OutStream);
                                                OutStream.WriteText(StrSubstNo(ReturnMsg, Remarks, Status));
                                                PostedTransferShipment.Modify();
                                            end;
                                        end;
                                    end;
                                end;
                    end;
            end else
                Error('Unable to connect %1', HttpResponse.HttpStatusCode());
        end else
            Error('Cannot connect,connection error');
    end;

    procedure SetEWBDatetimeFromJsonToken(JsonDateToken: JsonToken): DateTime
    var
        DateValue: Date;
        TimeValue: Time;
        DateTimeText: Text;
    begin
        // Extract the datetime string from the JSON token
        DateTimeText := JsonDateToken.AsValue().AsText();

        // Parse date and time parts
        Evaluate(DateValue, CopyStr(DateTimeText, 1, 10));  // Gets 'YYYY-MM-DD'
        Evaluate(TimeValue, CopyStr(DateTimeText, 12));     // Gets 'hh:mm:ss'

        // Assign to the DateTime field
        exit(CreateDateTime(DateValue, TimeValue));
    end;

    procedure GenerateSalesInvoiceDetails(InvoiceNo: Code[20])
    var
        PostedSalesInvoice: Record "Sales Invoice Header";
        Location: Record Location;
        State: Record State;
    begin
        PostedSalesInvoice.Reset();
        PostedSalesInvoice.SetRange("No.", InvoiceNo);
        if PostedSalesInvoice.FindFirst() then begin
            GlbTextVars := '';
            GlbTextVars += '{';
            WriteToGlbTextVar('action', 'UPDATEPARTB', 0, TRUE);
            GlbTextVars += '"data" : [';
            GlbTextVars += '{';
            WriteToGlbTextVar('Generator_Gstin', PostedSalesInvoice."Location GST Reg. No.", 0, TRUE);
            WriteToGlbTextVar('EwbNo', PostedSalesInvoice."E-Way Bill No.", 0, TRUE);
            if PostedSalesInvoice."LFS Mode of Transport" <> PostedSalesInvoice."LFS Mode of Transport"::"0" then
                case PostedSalesInvoice."LFS Mode of Transport" of
                    PostedSalesInvoice."LFS Mode of Transport"::"1":
                        WriteToGlbTextVar('TransportMode', 'Road', 0, TRUE);
                    PostedSalesInvoice."LFS Mode of Transport"::"2":
                        WriteToGlbTextVar('TransportMode', 'Rail', 0, TRUE);
                    PostedSalesInvoice."LFS Mode of Transport"::"3":
                        WriteToGlbTextVar('TransportMode', 'Air', 0, TRUE);
                    PostedSalesInvoice."LFS Mode of Transport"::"4":
                        WriteToGlbTextVar('TransportMode', 'Ship', 0, TRUE);
                end
            else
                WriteToGlbTextVar('TransportMode', 'null', 1, TRUE);
            if PostedSalesInvoice."Vehicle Type" <> PostedSalesInvoice."Vehicle Type"::" " then begin
                if PostedSalesInvoice."Vehicle Type" = PostedSalesInvoice."Vehicle Type"::ODC then
                    WriteToGlbTextVar('VehicleType', 'O', 0, TRUE)
                else
                    if PostedSalesInvoice."Vehicle Type" = PostedSalesInvoice."Vehicle Type"::Regular then
                        WriteToGlbTextVar('VehicleType', 'R', 0, TRUE);
            end else
                WriteToGlbTextVar('VehicleType', '', 1, TRUE);
            if PostedSalesInvoice."Vehicle No." <> '' then
                WriteToGlbTextVar('VehicleNo', PostedSalesInvoice."Vehicle No.", 0, TRUE)
            else
                WriteToGlbTextVar('VehicleNo', '', 0, TRUE);
            // WriteToGlbTextVar('TransDocNumber', PostedSalesInvoice."No.", 0, TRUE);
            // WriteToGlbTextVar('TransDocDate', Format(PostedSalesInvoice."Document Date", 0, '<Day,2>/<Month,2>/<Year4>'), 0, TRUE);
            WriteToGlbTextVar('TransDocNumber', '', 0, TRUE);
            WriteToGlbTextVar('TransDocDate', '', 0, TRUE);

            Location.Reset();
            Location.SetRange(Code, PostedSalesInvoice."Location Code");
            if Location.FindFirst() then begin
                State.Reset();
                State.SetRange(Code, Location."State Code");
                if State.FindFirst() then
                    WriteToGlbTextVar('StateName', State.Description, 0, TRUE);
                WriteToGlbTextVar('FromCityPlace', Location.City, 0, TRUE);
            end;
            WriteToGlbTextVar('VehicleReason', Format(PostedSalesInvoice."LFS E-Way Bill Vehicle Reason"), 0, TRUE);
            WriteToGlbTextVar('Remarks', PostedSalesInvoice."LFS E-Way Bill Remarks", 0, false);
            GlbTextVars += '}]}';

            Message(GlbTextVars);
            UpdatePartBEWAYBILL(GlbTextVars, PostedSalesInvoice."Location GST Reg. No.", PostedSalesInvoice."No.");
        end;
    end;

    procedure GenerateSalesCreditMemoDetails(CreditNo: Code[20])
    var
        PostedSalesCreditMemo: Record "Sales Cr.Memo Header";
        Location: Record Location;
        State: Record State;
    begin
        PostedSalesCreditMemo.Reset();
        PostedSalesCreditMemo.SetRange("No.", CreditNo);
        if PostedSalesCreditMemo.FindFirst() then begin
            GlbTextVars := '';
            GlbTextVars += '{';
            WriteToGlbTextVar('action', 'UPDATEPARTB', 0, TRUE);
            GlbTextVars += '"data" : [';
            GlbTextVars += '{';
            WriteToGlbTextVar('Generator_Gstin', PostedSalesCreditMemo."Location GST Reg. No.", 0, TRUE);
            WriteToGlbTextVar('EwbNo', PostedSalesCreditMemo."E-Way Bill No.", 0, TRUE);
            if PostedSalesCreditMemo."LFS Mode of Transport" <> PostedSalesCreditMemo."LFS Mode of Transport"::"0" then
                case PostedSalesCreditMemo."LFS Mode of Transport" of
                    PostedSalesCreditMemo."LFS Mode of Transport"::"1":
                        WriteToGlbTextVar('TransportMode', 'Road', 0, TRUE);
                    PostedSalesCreditMemo."LFS Mode of Transport"::"2":
                        WriteToGlbTextVar('TransportMode', 'Rail', 0, TRUE);
                    PostedSalesCreditMemo."LFS Mode of Transport"::"3":
                        WriteToGlbTextVar('TransportMode', 'Air', 0, TRUE);
                    PostedSalesCreditMemo."LFS Mode of Transport"::"4":
                        WriteToGlbTextVar('TransportMode', 'Ship', 0, true);
                end
            else
                WriteToGlbTextVar('TransportMode', 'null', 1, TRUE);
            if PostedSalesCreditMemo."Vehicle Type" <> PostedSalesCreditMemo."Vehicle Type"::" " then begin
                if PostedSalesCreditMemo."Vehicle Type" = PostedSalesCreditMemo."Vehicle Type"::ODC
                    then
                    WriteToGlbTextVar('VehicleType', 'O', 0, TRUE)
                else
                    if PostedSalesCreditMemo."Vehicle Type" = PostedSalesCreditMemo."Vehicle Type"::Regular
                        then
                        WriteToGlbTextVar('VehicleType', 'R', 0, TRUE);
            end
            else
                WriteToGlbTextVar('VehicleType', '', 1, TRUE);
            if PostedSalesCreditMemo."Vehicle No." <> '' then
                WriteToGlbTextVar('VehicleNo', PostedSalesCreditMemo."Vehicle No.", 0, TRUE)
            else
                WriteToGlbTextVar('VehicleNo', '', 0, TRUE);
            WriteToGlbTextVar('TransDocNumber', '', 0, TRUE);
            WriteToGlbTextVar('TransDocDate', '', 0, TRUE);

            Location.Reset();
            Location.SetRange(Code, PostedSalesCreditMemo."Location Code");
            if Location.FindFirst() then begin
                State.Reset();
                State.SetRange(Code, Location."State Code");
                if State.FindFirst() then
                    WriteToGlbTextVar('StateName', State.Description, 0, TRUE);
                WriteToGlbTextVar('FromCityPlace', Location.City, 0, TRUE);
            end;
            WriteToGlbTextVar('VehicleReason', Format(PostedSalesCreditMemo."LFS E-Way Bill Vehicle Reason"), 0, TRUE);
            WriteToGlbTextVar('Remarks', PostedSalesCreditMemo."LFS E-Way Bill Remarks", 0, false);
            GlbTextVars += '}]}';

            Message(GlbTextVars);
            UpdatePartBEWAYBILL(GlbTextVars, PostedSalesCreditMemo."Location GST Reg. No.", PostedSalesCreditMemo."No.");
        end;
    end;

    procedure GenerateTransferShipmentDetails(TransferNo: Code[20])
    var
        PostedTransferShipment: Record "Transfer Shipment Header";
        Location: Record Location;
        State: Record State;
    begin
        PostedTransferShipment.Reset();
        PostedTransferShipment.SetRange("No.", TransferNo);
        if PostedTransferShipment.FindFirst() then begin
            GlbTextVars := '';
            GlbTextVars += '{';
            WriteToGlbTextVar('action', 'UPDATEPARTB', 0, TRUE);
            GlbTextVars += '"data" : [';
            GlbTextVars += '{';
            Location.Get(PostedTransferShipment."Transfer-from Code");
            WriteToGlbTextVar('Generator_Gstin', Location."GST Registration No.", 0, TRUE);
            WriteToGlbTextVar('EwbNo', PostedTransferShipment."E-Way Bill No.", 0, TRUE);
            if PostedTransferShipment."LFS Mode of Transport" <> PostedTransferShipment."LFS Mode of Transport"::"0" then
                case PostedTransferShipment."LFS Mode of Transport" of
                    PostedTransferShipment."LFS Mode of Transport"::"1":
                        WriteToGlbTextVar('TransportMode', 'Road', 0, TRUE);
                    PostedTransferShipment."LFS Mode of Transport"::"2":
                        WriteToGlbTextVar('TransportMode', 'Rail', 0, TRUE);
                    PostedTransferShipment."LFS Mode of Transport"::"3":
                        WriteToGlbTextVar('TransportMode', 'Air', 0, TRUE);
                    PostedTransferShipment."LFS Mode of Transport"::"4":
                        WriteToGlbTextVar('TransportMode', 'Ship', 0, TRUE);
                end
            else
                WriteToGlbTextVar('TransportMode', 'null', 1, TRUE);
            if PostedTransferShipment."Vehicle Type" <> PostedTransferShipment."Vehicle Type"::" " then begin
                if PostedTransferShipment."Vehicle Type" = PostedTransferShipment."Vehicle Type"::ODC then
                    WriteToGlbTextVar('VehicleType', 'O', 0, TRUE)
                else
                    if PostedTransferShipment."Vehicle Type" = PostedTransferShipment."Vehicle Type"::Regular then
                        WriteToGlbTextVar('VehicleType', 'R', 0, TRUE);
            end else
                WriteToGlbTextVar('VehicleType', '', 1, TRUE);
            if PostedTransferShipment."Vehicle No." <> '' then
                WriteToGlbTextVar('VehicleNo', PostedTransferShipment."Vehicle No.", 0, TRUE)
            else
                WriteToGlbTextVar('VehicleNo', '', 0, TRUE);
            // WriteToGlbTextVar('TransDocNumber', PostedTransferShipment."No.", 0, TRUE);
            // WriteToGlbTextVar('TransDocDate', Format(PostedTransferShipment."Document Date", 0, '<Day,2>/<Month,2>/<Year4>'), 0, TRUE);
            WriteToGlbTextVar('TransDocNumber', '', 0, TRUE);
            WriteToGlbTextVar('TransDocDate', '', 0, TRUE);

            Location.Reset();
            Location.SetRange(Code, PostedTransferShipment."Transfer-from Code");
            if Location.FindFirst() then begin
                State.Reset();
                State.SetRange(Code, Location."State Code");
                if State.FindFirst() then
                    WriteToGlbTextVar('StateName', State.Description, 0, TRUE);
                WriteToGlbTextVar('FromCityPlace', Location.City, 0, TRUE);
            end;
            WriteToGlbTextVar('VehicleReason', Format(PostedTransferShipment."LFS E-Way Bill Vehicle Reason"), 0, TRUE);
            WriteToGlbTextVar('Remarks', PostedTransferShipment."LFS E-Way Bill Remarks", 0, false);
            GlbTextVars += '}]}';

            Message(GlbTextVars);
            Location.Reset();
            Location.Get(PostedTransferShipment."Transfer-from Code");
            UpdatePartBEWAYBILL(GlbTextVars, Location."GST Registration No.", PostedTransferShipment."No.");
        end;
    end;

    local procedure WriteToGlbTextVar(Label: Text; Value: Text; ValFormat: Option Text,Number; InsertComma: Boolean)
    var
        DoubleQuotesLbl: Label '"';
        CommaLbl: Label ',';
    begin
        IF Value <> '' THEN BEGIN
            IF ValFormat = ValFormat::Text THEN BEGIN
                IF InsertComma THEN
                    GlbTextVars += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + DoubleQuotesLbl + Value + DoubleQuotesLbl + CommaLbl
                ELSE
                    GlbTextVars += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + DoubleQuotesLbl + Value + DoubleQuotesLbl;
            END ELSE
                IF InsertComma THEN
                    GlbTextVars += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + Value + CommaLbl
                ELSE
                    GlbTextVars += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + Value;

        END ELSE
            IF ValFormat = ValFormat::Text THEN BEGIN
                IF InsertComma THEN
                    GlbTextVars += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + DoubleQuotesLbl + DoubleQuotesLbl + CommaLbl
                ELSE
                    GlbTextVars += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + DoubleQuotesLbl + DoubleQuotesLbl;
            END ELSE
                IF InsertComma THEN
                    GlbTextVars += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + DoubleQuotesLbl + '0' + DoubleQuotesLbl + CommaLbl
                ELSE
                    GlbTextVars += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + DoubleQuotesLbl + '0' + DoubleQuotesLbl;
    end;
}
