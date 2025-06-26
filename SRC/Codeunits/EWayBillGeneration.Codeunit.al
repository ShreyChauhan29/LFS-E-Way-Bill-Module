namespace LFSEWayBillModule.LFSEWayBillModule;
using Microsoft.Finance.GST.Base;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Foundation.Shipping;
using Microsoft.Sales.History;
codeunit 73100 "E-Way Bill Generation"
{
    Permissions = tabledata "Sales Invoice Header" = RM, tabledata "Transfer Shipment Header" = RM;

    var
        GlbTextVars: Text;

    procedure GenerateEWAYBILL(GlbTextVar: Text; GSTRegistrationNo: Code[20]; DocumentNo: Code[20])
    var
        GSTRegNos: Record "GST Registration Nos.";
        PostedSalesInvoice: Record "Sales Invoice Header";
        PostedTransferShipment: Record "Transfer Shipment Header";
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
        HttpHeader.Add('client_id', GSTRegNos."LFS E-Way Bill API ClientID");
        HttpHeader.Add('client_secret', GSTRegNos."LFS E-Way Bill APIClientSecret");
        HttpHeader.Add('IPAddress', GSTRegNos."LFS E-Way Bill API IP Address");
        HttpHeader.Add('user_name', GSTRegNos."LFS E-Way Bill API UserName");
        HttpHeader.Add('Gstin', GSTRegNos.Code);
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
                                                JSONObject.Get('EWB_NO', valueJSONToken);
                                                PostedSalesInvoice."E-Way Bill No." := Format(valueJSONToken.AsValue().AsText());
                                                JSONObject.Get('EWB_DATE', valueJSONToken);
                                                // PostedSalesInvoice."LFS E-Way Bill Date" := Format(valueJSONToken.AsValue().AsText());
                                                PostedSalesInvoice."LFS E-Way Bill Date" := valueJSONToken.AsValue().AsDateTime();
                                                JSONObject.Get('VALID_UPTO_DATE', valueJSONToken);
                                                // Message(Format(valueJSONToken.AsValue().AsText()));
                                                PostedSalesInvoice."LFS E-Way Bill Valid Upto Date" := valueJSONToken.AsValue().AsDateTime();
                                                PostedSalesInvoice."LFS E-Way Bill Message".CreateOutStream(OutStream);
                                                OutStream.WriteText(StrSubstNo(ReturnMsg, Remarks, Status));
                                                PostedSalesInvoice.Modify();
                                            end;
                                            PostedTransferShipment.Reset();
                                            PostedTransferShipment.SetRange("No.", DocumentNo);
                                            if PostedTransferShipment.FindFirst() then begin
                                                JSONObject.Get('EWB_NO', valueJSONToken);
                                                PostedTransferShipment."E-Way Bill No." := Format(valueJSONToken.AsValue().AsText());
                                                JSONObject.Get('EWB_DATE', valueJSONToken);
                                                PostedTransferShipment."LFS E-Way Bill Date" := valueJSONToken.AsValue().AsDateTime();
                                                JSONObject.Get('VALID_UPTO_DATE', valueJSONToken);
                                                PostedTransferShipment."LFS E-Way Bill Valid Upto Date" := valueJSONToken.AsValue().AsDateTime();
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
        ShippingAgent: Record "Shipping Agent";
    begin
        PostedSalesInvoice.Reset();
        PostedSalesInvoice.SetRange("No.", InvoiceNo);
        if PostedSalesInvoice.FindFirst() then begin
            GlbTextVars := '';
            GlbTextVars += '{';
            WriteToGlbTextVar('ACTION', 'EWAYBILL', 0, TRUE);
            WriteToGlbTextVar('Irn', PostedSalesInvoice."IRN Hash", 0, TRUE);
            WriteToGlbTextVar('Distance', '0', 0, TRUE);
            if PostedSalesInvoice."LFS Mode of Transport" <> PostedSalesInvoice."LFS Mode of Transport"::"0" then
                WriteToGlbTextVar('TransMode', Format(PostedSalesInvoice."LFS Mode of Transport"), 0, TRUE)
            else
                WriteToGlbTextVar('TransMode', 'null', 1, TRUE);
            ShippingAgent.Reset();
            ShippingAgent.SetRange(Code, PostedSalesInvoice."Shipping Agent Code");
            if ShippingAgent.FindFirst() then begin
                WriteToGlbTextVar('TransId', ShippingAgent."GST Registration No.", 0, TRUE);
                WriteToGlbTextVar('TransName', DELCHR(ShippingAgent.Name, '=', '"^([^\"])*$"'), 0, TRUE);
            end;
            WriteToGlbTextVar('TransDocDt', Format(PostedSalesInvoice."Document Date", 0, '<Day,2>/<Month,2>/<Year4>'), 0, TRUE);
            WriteToGlbTextVar('TransDocNo', PostedSalesInvoice."No.", 0, TRUE);
            if PostedSalesInvoice."Vehicle No." <> '' then
                WriteToGlbTextVar('VehNo', PostedSalesInvoice."Vehicle No.", 0, TRUE)
            else
                WriteToGlbTextVar('VehNo', 'null', 1, TRUE);
            if PostedSalesInvoice."Vehicle Type" <> PostedSalesInvoice."Vehicle Type"::" " then begin
                if PostedSalesInvoice."Vehicle Type" = PostedSalesInvoice."Vehicle Type"::ODC then
                    WriteToGlbTextVar('VehType', 'O', 0, TRUE)
                else
                    if PostedSalesInvoice."Vehicle Type" = PostedSalesInvoice."Vehicle Type"::Regular then
                        WriteToGlbTextVar('VehType', 'R', 0, TRUE);
            end else
                WriteToGlbTextVar('VehType', 'null', 1, TRUE);
            WriteToGlbTextVar('ExpShipDtls', 'null', 1, TRUE);
            WriteToGlbTextVar('DispDtls', 'null', 1, false);
            GlbTextVars += '}';
            Message(GlbTextVars);
            GenerateEWAYBILL(GlbTextVars, PostedSalesInvoice."Location GST Reg. No.", PostedSalesInvoice."No.");
        end;
    end;

    procedure GenerateTransferShipmentDetails(ShipmentNo: Code[20])
    var
        PostedTransferShipment: Record "Transfer Shipment Header";
        ShippingAgent: Record "Shipping Agent";
        Location: Record Location;
    begin
        PostedTransferShipment.Reset();
        PostedTransferShipment.SetRange("No.", ShipmentNo);
        if PostedTransferShipment.FindFirst() then begin
            GlbTextVars := '';
            GlbTextVars += '{';
            WriteToGlbTextVar('ACTION', 'EWAYBILL', 0, TRUE);
            WriteToGlbTextVar('Irn', PostedTransferShipment."IRN Hash", 0, TRUE);
            WriteToGlbTextVar('Distance', '0', 0, TRUE);
            if PostedTransferShipment."LFS Mode of Transport" <> PostedTransferShipment."LFS Mode of Transport"::"0" then
                WriteToGlbTextVar('TransMode', Format(PostedTransferShipment."LFS Mode of Transport"), 0, TRUE)
            else
                WriteToGlbTextVar('TransMode', 'null', 1, TRUE);
            ShippingAgent.Reset();
            ShippingAgent.SetRange(Code, PostedTransferShipment."Shipping Agent Code");
            if ShippingAgent.FindFirst() then begin
                WriteToGlbTextVar('TransId', ShippingAgent."GST Registration No.", 0, TRUE);
                WriteToGlbTextVar('TransName', DELCHR(ShippingAgent.Name, '=', '"^([^\"])*$"'), 0, TRUE);
            end;
            WriteToGlbTextVar('TransDocDt', Format(PostedTransferShipment."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'), 0, TRUE);
            WriteToGlbTextVar('TransDocNo', PostedTransferShipment."No.", 0, TRUE);
            if PostedTransferShipment."Vehicle No." <> '' then
                WriteToGlbTextVar('VehNo', PostedTransferShipment."Vehicle No.", 0, TRUE)
            else
                WriteToGlbTextVar('VehNo', 'null', 1, TRUE);
            if PostedTransferShipment."Vehicle Type" <> PostedTransferShipment."Vehicle Type"::" " then begin
                if PostedTransferShipment."Vehicle Type" = PostedTransferShipment."Vehicle Type"::ODC then
                    WriteToGlbTextVar('VehType', 'O', 0, TRUE)
                else
                    if PostedTransferShipment."Vehicle Type" = PostedTransferShipment."Vehicle Type"::Regular then
                        WriteToGlbTextVar('VehType', 'R', 0, TRUE);
            end else
                WriteToGlbTextVar('VehType', 'null', 1, TRUE);
            WriteToGlbTextVar('ExpShipDtls', 'null', 1, TRUE);
            WriteToGlbTextVar('DispDtls', 'null', 1, false);
            GlbTextVars += '}';
            Message(GlbTextVars);
            Location.GET(PostedTransferShipment."Transfer-from Code");
            GenerateEWAYBILL(GlbTextVars, Location."GST Registration No.", PostedTransferShipment."No.");
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

    procedure DownloadEwayBillPDFSalesInvocies(DocNo: Code[20])
    var
        PostedSalesInvoices: Record "Sales Invoice Header";
        GstRegNos: Record "GST Registration Nos.";
        URLtext: Text;
        Client: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpHeader: HttpHeaders;
        HttpContent: HttpContent;
        Response: Text;
        IStr: InStream;
    begin
        PostedSalesInvoices.Get(DocNo);
        GSTRegNos.Get(PostedSalesInvoices."Location GST Reg. No.");

        URLtext := GstRegNos."LFS E-Way Bill API URL" + '?GSTIN=' + GstRegNos.Code + '&EWBNO=' + PostedSalesInvoices."E-Way Bill No." + '&action=GETEWAYBILL';
        HttpRequest.Method := 'GET';
        HttpRequest.SetRequestUri(URLtext);
        HttpContent.GetHeaders(HttpHeader);
        HttpHeader.Add('PRIVATEKEY', GSTRegNos."LFS E-Way Bill PrivateKey");
        HttpHeader.Add('PRIVATEVALUE', GSTRegNos."LFS E-Way Bill PrivateValue");
        HttpHeader.Add('IP', GSTRegNos."LFS E-Way Bill API IP Address");
        HttpHeader.Remove('Content-Type');
        HttpHeader.Add('Content-Type', 'application/json');
        HttpRequest.Content(HttpContent);
        if Client.Send(HttpRequest, HttpResponse) then
            if HttpResponse.HttpStatusCode() = 200 then begin
                HttpResponse.Content.ReadAs(IStr);
                Response := PostedSalesInvoices."E-Way Bill No." + '.pdf';
                DownloadFromStream(IStr, 'Select file path', 'D:\Downloads\', '', Response);
            end;
    end;

    procedure DownloadEwayBillPDFTransferShipments(DocNo: Code[20])
    var
        PostedTransferShipment: Record "Transfer Shipment Header";
        GstRegNos: Record "GST Registration Nos.";
        Location: Record Location;
        URLtext: Text;
        Client: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpHeader: HttpHeaders;
        HttpContent: HttpContent;
        Response: Text;
        IStr: InStream;
    begin
        PostedTransferShipment.Get(DocNo);
        Location.Reset();
        Location.SetRange(Code, PostedTransferShipment."Transfer-from Code");
        if Location.FindFirst() then
            GSTRegNos.Get(Location."GST Registration No.");

        URLtext := GstRegNos."LFS E-Way Bill API URL" + '?GSTIN=' + GstRegNos.Code + '&EWBNO=' + PostedTransferShipment."E-Way Bill No." + '&action=GETEWAYBILL';
        HttpRequest.Method := 'GET';
        HttpRequest.SetRequestUri(URLtext);
        HttpContent.GetHeaders(HttpHeader);
        HttpHeader.Add('PRIVATEKEY', GSTRegNos."LFS E-Way Bill PrivateKey");
        HttpHeader.Add('PRIVATEVALUE', GSTRegNos."LFS E-Way Bill PrivateValue");
        HttpHeader.Add('IP', GSTRegNos."LFS E-Way Bill API IP Address");
        HttpHeader.Remove('Content-Type');
        HttpHeader.Add('Content-Type', 'application/json');
        HttpRequest.Content(HttpContent);
        if Client.Send(HttpRequest, HttpResponse) then
            if HttpResponse.HttpStatusCode() = 200 then begin
                HttpResponse.Content.ReadAs(IStr);
                Response := PostedTransferShipment."E-Way Bill No." + '.pdf';
                DownloadFromStream(IStr, 'Select file path', 'D:\Downloads\', '', Response);
            end;
    end;
}
