namespace LFSEWayBillModule.LFSEWayBillModule;
using Microsoft.Finance.GST.Base;
using Microsoft.Sales.History;
using Microsoft.Inventory.Location;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Transfer;

codeunit 73104 "LFS E-Way Bill Cancellation"
{
    Permissions = tabledata "Sales Invoice Header" = RM, tabledata "Transfer Shipment Header" = RM;

    var
        GlbTextVars: Text;


    procedure CancelEwayBill(GlbTextVar: Text; GSTRegistrationNo: Code[20]; DocumentNo: Code[20])
    var
        GSTRegNos: Record "GST Registration Nos.";
        PostedSalesInvoice: Record "Sales Invoice Header";
        PostedTransferShipment: Record "Transfer Shipment Header";
        HttpClient: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpHeader: HttpHeaders;
        HttpContent: HttpContent;
        Response: Text;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        ValueJsonToken: JsonToken;
        JsonArray: JsonArray;
        i: Integer;
#pragma warning disable AA0470
        ReturnMsg: Label 'Status : %1\ %2';
#pragma warning restore AA0470
        Status: Text;
        Remarks: text;
    begin
        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(GSTRegNos."LFS E-Way Bill API URL");
        HttpContent.WriteFrom(GlbTextVar);
        HttpContent.GetHeaders(HttpHeader);
        HttpHeader.Add('PRIVATEKEY', GSTRegNos."LFS E-Way Bill PrivateKey");
        HttpHeader.Add('PRIVATEVALUE', GSTRegNos."LFS E-Way Bill PrivateValue");
        HttpHeader.Add('IP', GSTRegNos."LFS E-Way Bill API IP Address");
        HttpHeader.Remove('Content-Type');
        HttpHeader.Add('Content-Type', 'application/json');
        HttpRequest.Content(HttpContent);
        if HttpClient.Send(HttpRequest, HttpResponse) then begin
            if HttpResponse.HttpStatusCode() = 200 then begin
                HttpResponse.Content.ReadAs(Response);
                if JsonToken.ReadFrom(Response) then
                    if JsonToken.IsObject then begin
                        JsonObject := JsonToken.AsObject();
                        JsonObject.Get('MessageId', ValueJsonToken);
                        if ValueJsonToken.AsValue().AsText() = '1' then
                            if JsonObject.Get('Data', JsonToken) then
                                if JsonToken.IsArray then begin
                                    JsonArray.ReadFrom(format(JsonToken));
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
                                                JsonObject.Get('CancelDate', ValueJsonToken);
                                                if not ValueJsonToken.AsValue().IsNull then begin
                                                    PostedSalesInvoice."LFS E-Way Bill Cancel Date" := valueJSONToken.AsValue().AsDateTime();
                                                    PostedSalesInvoice.Modify();
                                                end;
                                            end;
                                            PostedTransferShipment.Reset();
                                            PostedTransferShipment.SetRange("No.", DocumentNo);
                                            if PostedTransferShipment.FindFirst() then begin
                                                JsonObject.Get('CancelDate', ValueJsonToken);
                                                if not ValueJsonToken.AsValue().IsNull then begin
                                                    PostedTransferShipment."LFS E-Way Bill Cancel Date" := valueJSONToken.AsValue().AsDateTime();
                                                    PostedTransferShipment.Modify();
                                                end;
                                            end;
                                        end;
                                        Message(StrSubstNo(ReturnMsg, Remarks, Status));
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

    procedure GenerateCancelEwayBillSalesInvoice(DocNo: Code[20])
    var
        GSTRegNos: Record "GST Registration Nos.";
        PostedSalesInvoice: Record "Sales Invoice Header";
    begin
        PostedSalesInvoice.GET(DocNo);
        PostedSalesInvoice.TESTFIELD("LFS E-Way Bill Cancel Reason");
        PostedSalesInvoice.TestField("LFS E-Way Bill Cancel Remark");
        GSTRegNos.Get(PostedSalesInvoice."Location GST Reg. No.");
        GlbTextVars := '';
        GlbTextVars += '{';
        WriteToGlbTextVar('action', 'CANCEL', 0, TRUE);
        GlbTextVars += '"data": [';
        GlbTextVars += '{';
        WriteToGlbTextVar('GENERATOR_GSTIN', PostedSalesInvoice."Location GST Reg. No.", 0, TRUE);
        WriteToGlbTextVar('EwbNo', PostedSalesInvoice."E-Way Bill No.", 0, TRUE);
        WriteToGlbTextVar('CancelReason', Format(PostedSalesInvoice."LFS E-Way Bill Cancel Reason"), 0, TRUE);
        WriteToGlbTextVar('cancelRmrk', PostedSalesInvoice."LFS E-Way Bill Cancel Remark", 0, FALSE);
        GlbTextVars += '}';
        GlbTextVars += ']';
        GlbTextVars += '}';
    END;

    procedure GenerateCancelEwayBillTransferShipment(DocNo: Code[20])
    var
        GSTRegNos: Record "GST Registration Nos.";
        PostedTransferShipment: Record "Transfer Shipment Header";
        Location: Record Location;
        ReasonCode: Record "Reason Code";
    begin
        PostedTransferShipment.GET(DocNo);
        // PostedTransferShipment.TESTFIELD("LFS E-Way Bill Cancel Reason");
        // PostedTransferShipment.TestField("LFS E-Way Bill Cancel Remark");
        Location.Reset();
        Location.SetRange(Code, PostedTransferShipment."Transfer-from Code");
        if Location.FindFirst() then
            GSTRegNos.Get(Location."GST Registration No.");
        GlbTextVars := '';
        GlbTextVars += '{';
        WriteToGlbTextVar('action', 'CANCEL', 0, TRUE);
        GlbTextVars += '"data": [';
        GlbTextVars += '{';
        WriteToGlbTextVar('GENERATOR_GSTIN', Location."GST Registration No.", 0, TRUE);
        WriteToGlbTextVar('EwbNo', PostedTransferShipment."E-Way Bill No.", 0, TRUE);
        ReasonCode.Reset();
        // ReasonCode.SetRange(Code, PostedTransferShipment."Eway Bill Cancel Reason");
        if ReasonCode.FindFirst() then
            WriteToGlbTextVar('CancelReason', ReasonCode.Description, 0, TRUE);
        // WriteToGlbTextVar('cancelRmrk', PostedTransferShipment."Eway Bill Cancel Remark", 0, FALSE);
        GlbTextVars += '}';
        GlbTextVars += ']';
        GlbTextVars += '}';
    END;

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
