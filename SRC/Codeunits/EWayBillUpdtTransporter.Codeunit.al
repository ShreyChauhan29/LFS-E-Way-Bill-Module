namespace LFSEWayBillModule.LFSEWayBillModule;
using Microsoft.Sales.History;
using Microsoft.Inventory.Transfer;
using Microsoft.Inventory.Location;
using Microsoft.Finance.GST.Base;
using Microsoft.Foundation.Shipping;

codeunit 73103 "LFS EWay Bill Updt Transporter"
{
    Permissions = tabledata "Sales Invoice Header" = RM, tabledata "Transfer Shipment Header" = RM;

    var
        GlbTextVars: Text;

    procedure UpdatePartBEWAYBILL(GlbTextVar: Text; GSTRegistrationNo: Code[20]; DocumentNo: Code[20])
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
                                        JSONObject.Get('Remarks', JSONToken);
                                        Remarks := JSONToken.AsValue().AsText();
                                        JSONObject.Get('Status', JSONToken);
                                        Status := JSONToken.AsValue().AsText();
                                        if Status = 'FAILED' then
                                            Error('Status : %1\ %2', Remarks, Status);

                                        if DocumentNo <> '' then begin
                                            PostedSalesInvoice.Reset();
                                            PostedSalesInvoice.SetRange("No.", DocumentNo);
                                            if PostedSalesInvoice.FindFirst() then begin
                                                JSONObject.Get('EwbNo', valueJSONToken);
                                                JSONObject.Get('Transporter_Date', valueJSONToken);
                                                PostedSalesInvoice."LFS E-Way Bill TransporterDate" := CopyStr(valueJSONToken.AsValue().AsText(), 1, MaxStrLen(PostedSalesInvoice."LFS E-Way Bill TransporterDate"));
                                                PostedSalesInvoice."LFS E-Way Bill Message".CreateOutStream(OutStream);
                                                OutStream.WriteText(StrSubstNo(ReturnMsg, Remarks, Status));
                                                PostedSalesInvoice.Modify();
                                            end;
                                            PostedTransferShipment.Reset();
                                            PostedTransferShipment.SetRange("No.", DocumentNo);
                                            if PostedTransferShipment.FindFirst() then begin
                                                JSONObject.Get('EwbNo', valueJSONToken);
                                                JSONObject.Get('Transporter_Date', valueJSONToken);
                                                PostedTransferShipment."LFS E-Way Bill TransporterDate" := CopyStr(valueJSONToken.AsValue().AsText(), 1, MaxStrLen(PostedTransferShipment."LFS E-Way Bill TransporterDate"));
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
            WriteToGlbTextVar('action', 'UPDATETRANSPORTER', 0, TRUE);
            GlbTextVars += '"data" : [';
            GlbTextVars += '{';
            WriteToGlbTextVar('Generator_Gstin', PostedSalesInvoice."Location GST Reg. No.", 0, TRUE);
            WriteToGlbTextVar('EwbNo', PostedSalesInvoice."E-Way Bill No.", 0, TRUE);
            ShippingAgent.Reset();
            ShippingAgent.SetRange(Code, PostedSalesInvoice."Shipping Agent Code");
            if ShippingAgent.FindFirst() then
                WriteToGlbTextVar('Transport_Gstin', ShippingAgent."GST Registration No.", 0, false);
            GlbTextVars += '}]}';

            Message(GlbTextVars);
            UpdatePartBEWAYBILL(GlbTextVars, PostedSalesInvoice."Location GST Reg. No.", PostedSalesInvoice."No.");
        end;
    end;

    procedure GenerateTransferShipmentDetails(TransferNo: Code[20])
    var
        PostedTransferShipment: Record "Transfer Shipment Header";
        ShippingAgent: Record "Shipping Agent";
        Location: Record Location;
    begin
        PostedTransferShipment.Reset();
        PostedTransferShipment.SetRange("No.", TransferNo);
        if PostedTransferShipment.FindFirst() then begin
            GlbTextVars := '';
            GlbTextVars += '{';
            WriteToGlbTextVar('action', 'UPDATETRANSPORTER', 0, TRUE);
            GlbTextVars += '"data" : [';
            GlbTextVars += '{';
            Location.Reset();
            Location.Get(PostedTransferShipment."Transfer-from Code");
            WriteToGlbTextVar('Generator_Gstin', Location."GST Registration No.", 0, TRUE);
            WriteToGlbTextVar('EwbNo', PostedTransferShipment."E-Way Bill No.", 0, TRUE);
            ShippingAgent.Reset();
            ShippingAgent.SetRange(Code, PostedTransferShipment."Shipping Agent Code");
            if ShippingAgent.FindFirst() then
                WriteToGlbTextVar('Transport_Gstin', ShippingAgent."GST Registration No.", 0, false);
            GlbTextVars += '}]}';

            Message(GlbTextVars);
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
