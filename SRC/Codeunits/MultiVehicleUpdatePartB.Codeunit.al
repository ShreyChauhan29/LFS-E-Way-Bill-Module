namespace LFSEWayBillModule.LFSEWayBillModule;
using Microsoft.Sales.History;
using Microsoft.Inventory.Transfer;
using Microsoft.Finance.GST.Base;
using Microsoft.Inventory.Location;
using Microsoft.Finance.TaxBase;
using Microsoft.Sales.Customer;

codeunit 73106 "LFS Multi Vehicle UpdatePart-B"
{
    Permissions = tabledata "Sales Invoice Header" = RM, tabledata "Transfer Shipment Header" = RM, tabledata "LFS Multiple Vehicle E-WayBill" = RM;

    var
        GlbTextVars: Text;

    procedure UpdatePartBMultipleVehicleEWAYBILL(GlbTextVar: Text; GSTRegistrationNo: Code[20]; DocumentNo: Code[20])
    var
        GSTRegNos: Record "GST Registration Nos.";
        PostedSalesInvoice: Record "Sales Invoice Header";
        PostedTransferShipment: Record "Transfer Shipment Header";
        MultipleVehicleEWayBill: Record "LFS Multiple Vehicle E-WayBill";
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
        JSONArray: JsonArray;
        i: Integer;
        OutStream: OutStream;
    begin
        GSTRegNos.Reset();
        GSTRegNos.Get(GSTRegistrationNo);
        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(GSTRegNos."LFS E-Way Bill/Invoice API URL");
        HttpContent.WriteFrom(GlbTextVar);
        HttpContent.GetHeaders(HttpHeader);
        HttpHeader.Add('PRIVATEKEY', GSTRegNos."LFS E-Way Bill PrivateKey");
        HttpHeader.Add('PRIVATEVALUE', GSTRegNos."LFS E-Way Bill PrivateValue");
        HttpHeader.Add('IP', GSTRegNos."LFS E-Way Bill API IP Address");
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
                                        JSONObject.Get('REMARKS', JSONToken);
                                        Remarks := JSONToken.AsValue().AsText();
                                        JSONObject.Get('STATUS', JSONToken);
                                        Status := JSONToken.AsValue().AsText();
                                        if Status = 'FAILED' then
                                            Error('Status : %1\ %2', Remarks, Status);

                                        if DocumentNo <> '' then begin
                                            PostedSalesInvoice.Reset();
                                            PostedSalesInvoice.SetRange("No.", DocumentNo);
                                            if PostedSalesInvoice.FindFirst() then begin
                                                JSONObject.Get('groupNo', valueJSONToken);
                                                MultipleVehicleEWayBill.Reset();
                                                MultipleVehicleEWayBill.SetRange("LFS Document No. ", PostedSalesInvoice."No.");
                                                MultipleVehicleEWayBill.SetRange("LFS Group No.", valueJSONToken.AsValue().AsInteger());
                                                if MultipleVehicleEWayBill.FindFirst() then begin
                                                    JSONObject.Get('VehicleAddedDate', valueJSONToken);
                                                    MultipleVehicleEWayBill."LFS Vehicle Added Date" := valueJSONToken.AsValue().AsDateTime();
                                                    MultipleVehicleEWayBill.Modify();
                                                end;
                                                PostedSalesInvoice."LFS E-Way Bill Message".CreateOutStream(OutStream);
                                                OutStream.WriteText(StrSubstNo(ReturnMsg, Remarks, Status));
                                                PostedSalesInvoice.Modify();
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

    procedure GenerateSalesInvoiceDetails(InvoiceNo: Code[20])
    var
        PostedSalesInvoice: Record "Sales Invoice Header";
        MultipleVehicleEWayBill: Record "LFS Multiple Vehicle E-WayBill";
        ShiptoAddress: Record "Ship-to Address";
        Location: Record Location;
        State: Record State;
        TotalCount: Integer;
        Increment: Integer;
    // ShippingAgent: Record "Shipping Agent";
    begin
        PostedSalesInvoice.Reset();
        PostedSalesInvoice.SetRange("No.", InvoiceNo);
        if PostedSalesInvoice.FindFirst() then begin
            GlbTextVars := '';
            GlbTextVars += '{';
            WriteToGlbTextVar('ACTION', 'MUTIVEHICLEUPDATE', 0, TRUE);
            GlbTextVars += '"data" : [';
            MultipleVehicleEWayBill.Reset();
            MultipleVehicleEWayBill.SetRange("LFS Document No. ", InvoiceNo);
            if MultipleVehicleEWayBill.FindSet() then
                repeat
                    TotalCount := MultipleVehicleEWayBill.Count;
                    GlbTextVars += '{';
                    WriteToGlbTextVar('Generator_Gstin', PostedSalesInvoice."Location GST Reg. No.", 0, TRUE);
                    WriteToGlbTextVar('EwbNo', PostedSalesInvoice."E-Way Bill No.", 0, TRUE);
                    WriteToGlbTextVar('GroupNo', Format(MultipleVehicleEWayBill."LFS Group No."), 0, TRUE);
                    WriteToGlbTextVar('NewVehicleNo', MultipleVehicleEWayBill."LFS New Vehicle No.", 0, true);
                    WriteToGlbTextVar('OldvehicleNo', MultipleVehicleEWayBill."LFS Old Vehicle No.", 0, true);
                    WriteToGlbTextVar('OldTranNo', '', 0, true);
                    WriteToGlbTextVar('NewTranNo', '', 0, true);
                    if PostedSalesInvoice."LFS Mode of Transport" <> PostedSalesInvoice."LFS Mode of Transport"::"0" then
                        case PostedSalesInvoice."LFS Mode of Transport" of
                            PostedSalesInvoice."LFS Mode of Transport"::"1":
                                WriteToGlbTextVar('TransMode', '1', 0, TRUE);
                            PostedSalesInvoice."LFS Mode of Transport"::"2":
                                WriteToGlbTextVar('TransMode', '2', 0, TRUE);
                            PostedSalesInvoice."LFS Mode of Transport"::"3":
                                WriteToGlbTextVar('TransMode', '3', 0, TRUE);
                            PostedSalesInvoice."LFS Mode of Transport"::"4":
                                WriteToGlbTextVar('TransMode', '4', 0, TRUE);
                        end
                    else
                        WriteToGlbTextVar('TransMode', 'null', 1, TRUE);
                    // WriteToGlbTextVar('TransMode', Format(PostedSalesInvoice."LFS Mode of Transport"), 0, true);
                    Location.Reset();
                    Location.SetRange(Code, PostedSalesInvoice."Location Code");
                    if Location.FindFirst() then begin
                        WriteToGlbTextVar('FromPlace', Location.City, 0, true);
                        State.Reset();
                        State.SetRange(Code, Location."State Code");
                        if State.FindFirst() then
                            WriteToGlbTextVar('FromState', State.Description, 0, true);
                    end;
                    WriteToGlbTextVar('Remarks', 'null', 1, true);

                    WriteToGlbTextVar('Reason', 'First Time', 0, true);
                    Increment += 1;
                    if TotalCount > Increment then
                        GlbTextVars += '},'
                    else
                        GlbTextVars += '}'

                until MultipleVehicleEWayBill.Next() = 0;
            GlbTextVars += ']}';
            Message(GlbTextVars);
            UpdatePartBMultipleVehicleEWAYBILL(GlbTextVars, PostedSalesInvoice."Location GST Reg. No.", PostedSalesInvoice."No.");
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
