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
        GlbTextVars, GlbTextVarAuth : Text;

    procedure AuthenticateAPI(GSTRegistrationNo: Code[20])
    var
        GSTRegNos: Record "GST Registration Nos.";
        MessageID: Text;
        L_Message: Text;
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Header: HttpHeaders;
        Content: HttpContent;
        JsonToken: JsonToken;
        JsonObject: JsonObject;

    begin
        GSTRegNos.Get(GSTRegistrationNo);
        GSTRegNos.TestField("LFS E-Way Bill API ClientID");
        GSTRegNos.TestField("LFS E-Way Bill APIClientSecret");
        GSTRegNos.TestField("LFS E-Way Bill API IP Address");
        GSTRegNos.TestField("LFS E-Way Bill API UserName");
        GSTRegNos.TestField("LFS E-Way Bill API Password");
        GSTRegNos.TestField(Description);
        GlbTextVarAuth := '';
        GlbTextVarAuth += '{';
        WriteToGlbTextVar1('action', 'ACCESSTOKEN', 0, TRUE);
        WriteToGlbTextVar1('UserName', GSTRegNos."LFS E-Way Bill API UserName", 0, TRUE);
        WriteToGlbTextVar1('Password', GSTRegNos."LFS E-Way Bill API Password", 0, TRUE);
        WriteToGlbTextVar1('Gstin', GSTRegNos.Code, 0, FALSE);
        GlbTextVarAuth += '}';

        Request.Method := 'Post';
        Request.SetRequestUri(GSTRegNos."LFS E-Way Bill AuthenticateURL");
        Content.WriteFrom(GlbTextVarAuth);
        Content.GetHeaders(Header);
        Header.Add('client_id', GSTRegNos."LFS E-Way Bill API ClientID");
        Header.Add('client_secret', GSTRegNos."LFS E-Way Bill APIClientSecret");
        Header.Add('IPAddress', GSTRegNos."LFS E-Way Bill API IP Address");
        Header.Remove('Content-Type');
        Header.Add('Content-Type', 'application/json');
        Request.Content(Content);
        if Client.Send(Request, Response) then begin
            if Response.IsSuccessStatusCode then begin
                Response.Content.ReadAs(L_Message);
                JsonObject.ReadFrom(L_Message);
                if JsonObject.Get('MessageId', JsonToken) then
                    MessageID := JsonToken.AsValue().AsText();

            end else
                Error('Unable to authenticate %1', Response.HttpStatusCode());
        end else
            Error('Cannot connect,connection error');

        IF MessageID = '0' THEN
            ERROR(L_Message)
    end;

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
        JsonValue: JsonValue;
        // JSONArray: JsonArray;
        // i: Integer;
        OutStream: OutStream;
    begin
        GSTRegNos.Reset();
        GSTRegNos.Get(GSTRegistrationNo);
        AuthenticateAPI(GSTRegNos.Code);
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

                        // Check MessageId = 1
                        if JSONObject.Get('MessageId', valueJSONToken) then
                            if valueJSONToken.AsValue().AsInteger() = 1 then begin
                                // Read Status from the root, not Data
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
                                if JSONObject.Get('Data', valueJSONToken) then
                                    if valueJSONToken.IsObject then begin
                                        JSONObject := valueJSONToken.AsObject();

                                        // Extract Remarks and Status (can be null)
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

                                        if Status = 'FAILED' then
                                            Error('Status : %1\ %2', Remarks, Status);

                                        if DocumentNo <> '' then begin
                                            // Update Posted Sales Invoice
                                            PostedSalesInvoice.Reset();
                                            PostedSalesInvoice.SetRange("No.", DocumentNo);
                                            if PostedSalesInvoice.FindFirst() then begin
                                                if JSONObject.Get('EwbNo', valueJSONToken) then
                                                    PostedSalesInvoice."E-Way Bill No." := CopyStr(valueJSONToken.AsValue().AsText(), 1, MaxStrLen(PostedSalesInvoice."E-Way Bill No."));

                                                if JSONObject.Get('EwbDt', valueJSONToken) then
                                                    PostedSalesInvoice."LFS E-Way Bill Date" := SetEWBDatetimeFromJsonToken(valueJSONToken);

                                                if JSONObject.Get('EwbValidTill', valueJSONToken) then
                                                    PostedSalesInvoice."LFS E-Way Bill Valid Upto Date" := SetEWBDatetimeFromJsonToken(valueJSONToken);

                                                PostedSalesInvoice."LFS E-Way Bill Message".CreateOutStream(OutStream);
                                                OutStream.WriteText(StrSubstNo(ReturnMsg, Remarks, Status));
                                                PostedSalesInvoice.Modify();
                                            end;

                                            // Update Posted Transfer Shipment
                                            PostedTransferShipment.Reset();
                                            PostedTransferShipment.SetRange("No.", DocumentNo);
                                            if PostedTransferShipment.FindFirst() then begin
                                                if JSONObject.Get('EwbNo', valueJSONToken) then
                                                    PostedTransferShipment."E-Way Bill No." := CopyStr(valueJSONToken.AsValue().AsText(), 1, MaxStrLen(PostedTransferShipment."E-Way Bill No."));

                                                if JSONObject.Get('EwbDt', valueJSONToken) then
                                                    PostedTransferShipment."LFS E-Way Bill Date" := SetEWBDatetimeFromJsonToken(valueJSONToken);

                                                if JSONObject.Get('EwbValidTill', valueJSONToken) then
                                                    PostedTransferShipment."LFS E-Way Bill Valid Upto Date" := SetEWBDatetimeFromJsonToken(valueJSONToken);

                                                PostedTransferShipment."LFS E-Way Bill Message".CreateOutStream(OutStream);
                                                OutStream.WriteText(StrSubstNo(ReturnMsg, Remarks, Status));
                                                PostedTransferShipment.Modify();
                                            end;
                                        end;
                                    end;
                            end;
                    end;
            end else
                Error('Unable to connect %1', HttpResponse.HttpStatusCode())
        end else
            Error('Cannot connect, connection error');

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
            if PostedSalesInvoice."Vehicle No." <> '' then
                if (PostedSalesInvoice."LFS Mode of Transport" <> PostedSalesInvoice."LFS Mode of Transport"::"0") then
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
                        WriteToGlbTextVar('TransMode', 'null', 1, TRUE)
                else
                    WriteToGlbTextVar('TransMode', 'null', 1, TRUE);
            ShippingAgent.Reset();
            ShippingAgent.SetRange(Code, PostedSalesInvoice."Shipping Agent Code");
            if ShippingAgent.FindFirst() then begin
                WriteToGlbTextVar('TransId', ShippingAgent."GST Registration No.", 0, TRUE);
                WriteToGlbTextVar('TransName', DELCHR(ShippingAgent.Name, '=', '"^([^\"])*$"'), 0, TRUE);
            end;
            // WriteToGlbTextVar('TransDocDt', Format(PostedSalesInvoice."Document Date", 0, '<Day,2>/<Month,2>/<Year4>'), 0, TRUE);
            // WriteToGlbTextVar('TransDocNo', PostedSalesInvoice."No.", 0, TRUE);
            WriteToGlbTextVar('TransDocDt', 'null', 1, TRUE);
            WriteToGlbTextVar('TransDocNo', 'null', 1, TRUE);
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
            if PostedTransferShipment."Vehicle No." <> '' then
                if PostedTransferShipment."LFS Mode of Transport" <> PostedTransferShipment."LFS Mode of Transport"::"0" then
                    case PostedTransferShipment."LFS Mode of Transport" of
                        PostedTransferShipment."LFS Mode of Transport"::"1":
                            WriteToGlbTextVar('TransMode', '1', 0, TRUE);
                        PostedTransferShipment."LFS Mode of Transport"::"2":
                            WriteToGlbTextVar('TransMode', '2', 0, TRUE);
                        PostedTransferShipment."LFS Mode of Transport"::"3":
                            WriteToGlbTextVar('TransMode', '3', 0, TRUE);
                        PostedTransferShipment."LFS Mode of Transport"::"4":
                            WriteToGlbTextVar('TransMode', '4', 0, TRUE);
                    end
                else
                    WriteToGlbTextVar('TransMode', 'null', 1, TRUE)
            else
                WriteToGlbTextVar('TransMode', 'null', 1, TRUE);
            ShippingAgent.Reset();
            ShippingAgent.SetRange(Code, PostedTransferShipment."Shipping Agent Code");
            if ShippingAgent.FindFirst() then begin
                WriteToGlbTextVar('TransId', ShippingAgent."GST Registration No.", 0, TRUE);
                WriteToGlbTextVar('TransName', DELCHR(ShippingAgent.Name, '=', '"^([^\"])*$"'), 0, TRUE);
            end;
            // WriteToGlbTextVar('TransDocDt', Format(PostedTransferShipment."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'), 0, TRUE);
            // WriteToGlbTextVar('TransDocNo', PostedTransferShipment."No.", 0, TRUE);
            WriteToGlbTextVar('TransDocDt', 'null', 1, TRUE);
            WriteToGlbTextVar('TransDocNo', 'null', 1, TRUE);
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

    local procedure WriteToGlbTextVar1(Label: Text; Value: Text; ValFormat: Option Text,Number; InsertComma: Boolean)
    var
        DoubleQuotesLbl: Label '"';
        CommaLbl: Label ',';
    begin
        IF Value <> '' THEN BEGIN
            IF ValFormat = ValFormat::Text THEN BEGIN
                IF InsertComma THEN
                    GlbTextVarAuth += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + DoubleQuotesLbl + Value + DoubleQuotesLbl + CommaLbl
                ELSE
                    GlbTextVarAuth += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + DoubleQuotesLbl + Value + DoubleQuotesLbl;
            END ELSE
                IF InsertComma THEN
                    GlbTextVarAuth += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + Value + CommaLbl
                ELSE
                    GlbTextVarAuth += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + Value;

        END ELSE
            IF ValFormat = ValFormat::Text THEN BEGIN
                IF InsertComma THEN
                    GlbTextVarAuth += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + DoubleQuotesLbl + DoubleQuotesLbl + CommaLbl
                ELSE
                    GlbTextVarAuth += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + DoubleQuotesLbl + DoubleQuotesLbl;
            END ELSE
                IF InsertComma THEN
                    GlbTextVarAuth += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + DoubleQuotesLbl + '0' + DoubleQuotesLbl + CommaLbl
                ELSE
                    GlbTextVarAuth += DoubleQuotesLbl + Label + DoubleQuotesLbl + ': ' + DoubleQuotesLbl + '0' + DoubleQuotesLbl;
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
