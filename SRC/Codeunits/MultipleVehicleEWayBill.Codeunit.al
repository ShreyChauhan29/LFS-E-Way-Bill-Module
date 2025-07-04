namespace LFSEWayBillModule.LFSEWayBillModule;
using Microsoft.Sales.History;
using Microsoft.Inventory.Transfer;
using Microsoft.Sales.Customer;
using Microsoft.Finance.TaxBase;
using Microsoft.Inventory.Location;
using Microsoft.Finance.GST.Base;

codeunit 73105 "LFS Multiple Vehicle E-WayBill"
{
    Permissions = tabledata "Sales Invoice Header" = RM, tabledata "Transfer Shipment Header" = RM, tabledata "LFS Multiple Vehicle E-WayBill" = RM;

    var
        GlbTextVars: Text;

    procedure GenerateMultipleVehicleEWAYBILL(GlbTextVar: Text; GSTRegistrationNo: Code[20]; DocumentNo: Code[20])
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
        DataObject: JsonObject;
        groupNoToken: JsonToken;
        groupNo: Integer;
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
                                                JSONObject.Get('groupNo', valueJSONToken);
                                                MultipleVehicleEWayBill.Reset();
                                                MultipleVehicleEWayBill.SetRange("LFS Document No. ", PostedSalesInvoice."No.");
                                                if MultipleVehicleEWayBill.FindFirst() then
                                                    MultipleVehicleEWayBill."LFS Group No." := valueJSONToken.AsValue().AsInteger();
                                                MultipleVehicleEWayBill.Modify();
                                                PostedSalesInvoice."LFS E-Way Bill Message".CreateOutStream(OutStream);
                                                OutStream.WriteText(StrSubstNo(ReturnMsg, Remarks, Status));
                                                PostedSalesInvoice.Modify();
                                                AddVehicleDetailsSalesInvoiceDetails(DocumentNo);
                                            end;


                                            // Parse the 'Data' array from JSON
                                            if JSONObject.Get('Data', JSONToken) then
                                                if JSONToken.IsArray then begin
                                                    JSONArray.ReadFrom(FORMAT(JSONToken));

                                                    for i := 0 to JSONArray.Count() - 1 do begin
                                                        if JSONArray.Get(i, JSONToken) then
                                                            DataObject := JSONToken.AsObject();

                                                        // Extract groupNo
                                                        if DataObject.Get('groupNo', groupNoToken) then begin
                                                            groupNo := groupNoToken.AsValue().AsInteger();
                                                            // Check if entry exists for this document and group

                                                            PostedTransferShipment.Reset();
                                                            PostedTransferShipment.SetRange("No.", DocumentNo);
                                                            if PostedTransferShipment.FindFirst() then begin
                                                                JSONObject.Get('groupNo', valueJSONToken);
                                                                MultipleVehicleEWayBill.Reset();
                                                                MultipleVehicleEWayBill.SetRange("LFS Document No. ", PostedTransferShipment."No.");
                                                                MultipleVehicleEWayBill.SetRange("LFS Group No.", 0);
                                                                if MultipleVehicleEWayBill.FindFirst() then begin
                                                                    MultipleVehicleEWayBill."LFS Group No." := valueJSONToken.AsValue().AsInteger();
                                                                    Commit();
                                                                    MultipleVehicleEWayBill.Modify();
                                                                end;
                                                            end;
                                                        end;
                                                    end;
                                                    AddVehicleDetailsTransferShipmentDetails(DocumentNo);
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

    procedure AddMultipleVehicleEWAYBILL(GlbTextVar: Text; GSTRegistrationNo: Code[20]; DocumentNo: Code[20])
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
        DataObject: JsonObject;
        groupNoToken: JsonToken;
        groupNos: Integer;
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
                                                JSONObject.Get('GroupNo', valueJSONToken);
                                                groupNos := valueJSONToken.AsValue().AsInteger();
                                                MultipleVehicleEWayBill.Reset();
                                                MultipleVehicleEWayBill.SetRange("LFS Document No. ", PostedSalesInvoice."No.");
                                                MultipleVehicleEWayBill.SetRange("LFS Group No.", groupNos);
                                                if MultipleVehicleEWayBill.FindFirst() then begin
                                                    JSONObject.Get('VehicleAddedDate', valueJSONToken);
                                                    MultipleVehicleEWayBill."LFS Vehicle Added Date" := CopyStr(valueJSONToken.AsValue().AsText(), 1, MaxStrLen(MultipleVehicleEWayBill."LFS Vehicle Added Date"));
                                                    MultipleVehicleEWayBill.Modify();
                                                end;
                                                PostedSalesInvoice."LFS E-Way Bill Message".CreateOutStream(OutStream);
                                                OutStream.WriteText(StrSubstNo(ReturnMsg, Remarks, Status));
                                                PostedSalesInvoice.Modify();
                                            end;

                                            // Parse the 'Data' array from JSON
                                            if JSONObject.Get('Data', JSONToken) then
                                                if JSONToken.IsArray then begin
                                                    JSONArray.ReadFrom(FORMAT(JSONToken));

                                                    for i := 0 to JSONArray.Count() - 1 do begin
                                                        if JSONArray.Get(i, JSONToken) then
                                                            DataObject := JSONToken.AsObject();

                                                        // Extract groupNo
                                                        if DataObject.Get('groupNo', groupNoToken) then begin
                                                            groupNos := groupNoToken.AsValue().AsInteger();
                                                            // Check if entry exists for this document and group

                                                            PostedTransferShipment.Reset();
                                                            PostedTransferShipment.SetRange("No.", DocumentNo);
                                                            if PostedTransferShipment.FindFirst() then begin
                                                                MultipleVehicleEWayBill.Reset();
                                                                MultipleVehicleEWayBill.SetRange("LFS Document No. ", PostedTransferShipment."No.");
                                                                MultipleVehicleEWayBill.SetRange("LFS Group No.", groupNos);
                                                                MultipleVehicleEWayBill.SetRange("LFS Vehicle Added Date", '');
                                                                if MultipleVehicleEWayBill.FindFirst() then begin
                                                                    MultipleVehicleEWayBill."LFS Group No." := valueJSONToken.AsValue().AsInteger();
                                                                    Commit();
                                                                    MultipleVehicleEWayBill.Modify();
                                                                end;
                                                            end;
                                                        end;
                                                    end;
                                                    AddVehicleDetailsTransferShipmentDetails(DocumentNo);
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
            WriteToGlbTextVar('action', 'CREATEGROUP', 0, TRUE);
            GlbTextVars += '"data" : [';
            MultipleVehicleEWayBill.Reset();
            MultipleVehicleEWayBill.SetRange("LFS Document No. ", InvoiceNo);
            if MultipleVehicleEWayBill.FindSet() then
                repeat
                    TotalCount := MultipleVehicleEWayBill.Count;
                    GlbTextVars += '{';
                    WriteToGlbTextVar('Generator_Gstin', PostedSalesInvoice."Location GST Reg. No.", 0, TRUE);
                    WriteToGlbTextVar('EwbNo', PostedSalesInvoice."E-Way Bill No.", 0, TRUE);
                    WriteToGlbTextVar('Reason', 'First Time', 0, TRUE);
                    WriteToGlbTextVar('Remarks', 'null', 1, true);
                    Location.Reset();
                    Location.SetRange(Code, PostedSalesInvoice."Location Code");
                    if Location.FindFirst() then begin
                        WriteToGlbTextVar('FromPlace', Location.City, 0, true);
                        State.Reset();
                        State.SetRange(Code, Location."State Code");
                        if State.FindFirst() then
                            WriteToGlbTextVar('FromState', State.Description, 0, true);
                    end;
                    if PostedSalesInvoice."Ship-to Code" <> '' then begin
                        ShiptoAddress.Reset();
                        ShiptoAddress.SetRange(Code, PostedSalesInvoice."Ship-to Code");
                        if ShiptoAddress.FindFirst() then begin
                            Location.Reset();
                            Location.SetRange(Code, ShiptoAddress."Location Code");
                            if Location.FindFirst() then begin
                                WriteToGlbTextVar('ToPlace', Location.City, 0, true);
                                State.Reset();
                                State.SetRange(Code, Location."State Code");
                                if State.FindFirst() then
                                    WriteToGlbTextVar('ToState', State.Description, 0, true);
                            end;
                        end;
                    end;

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
                    // WriteToGlbTextVar('TransportMode', Format(PostedSalesInvoice."LFS Mode of Transport"), 0, true);

                    WriteToGlbTextVar('TotalQuantity', Format(MultipleVehicleEWayBill."LFS Total Quantity"), 0, true);
                    WriteToGlbTextVar('UOM', MultipleVehicleEWayBill."LFS Unit of Measure", 0, false);
                    Increment += 1;
                    if TotalCount > Increment then
                        GlbTextVars += '},'
                    else
                        GlbTextVars += '}'

                until MultipleVehicleEWayBill.Next() = 0;
            GlbTextVars += ']}';
            Message(GlbTextVars);
            GenerateMultipleVehicleEWAYBILL(GlbTextVars, PostedSalesInvoice."Location GST Reg. No.", PostedSalesInvoice."No.");
        end;
    end;

    procedure AddVehicleDetailsSalesInvoiceDetails(InvoiceNo: Code[20])
    var
        PostedSalesInvoice: Record "Sales Invoice Header";
        MultipleVehicleEWayBill: Record "LFS Multiple Vehicle E-WayBill";
        TotalCount: Integer;
        Increment: Integer;
    begin
        PostedSalesInvoice.Reset();
        PostedSalesInvoice.SetRange("No.", InvoiceNo);
        if PostedSalesInvoice.FindFirst() then begin
            GlbTextVars := '';
            GlbTextVars += '{';
            WriteToGlbTextVar('action', 'MUTIVEHICLEADD', 0, TRUE);
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
                    WriteToGlbTextVar('VehicleNo', MultipleVehicleEWayBill."LFS New Vehicle No.", 0, true);
                    WriteToGlbTextVar('TransDocDate', '', 0, true);
                    WriteToGlbTextVar('TransDocNumber', '', 0, true);
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
                    // WriteToGlbTextVar('TransportMode', Format(PostedSalesInvoice."LFS Mode of Transport"), 0, true);
                    WriteToGlbTextVar('Quantity', Format(MultipleVehicleEWayBill."LFS Total Quantity"), 0, false);

                    Increment += 1;
                    if TotalCount > Increment then
                        GlbTextVars += '},'
                    else
                        GlbTextVars += '}'

                until MultipleVehicleEWayBill.Next() = 0;
            GlbTextVars += ']}';
            Message(GlbTextVars);
            AddMultipleVehicleEWAYBILL(GlbTextVars, PostedSalesInvoice."Location GST Reg. No.", PostedSalesInvoice."No.");
        end;
    end;

    procedure GenerateTransferShipmentDetails(ShipmentNo: Code[20])
    var
        PostedTransferShipment: Record "Transfer Shipment Header";
        MultipleVehicleEWayBill: Record "LFS Multiple Vehicle E-WayBill";
        // ShiptoAddress: Record "Ship-to Address";
        Location: Record Location;
        State: Record State;
        TotalCount: Integer;
        Increment: Integer;
    // ShippingAgent: Record "Shipping Agent";
    begin
        PostedTransferShipment.Reset();
        PostedTransferShipment.SetRange("No.", ShipmentNo);
        if PostedTransferShipment.FindFirst() then begin
            GlbTextVars := '';
            GlbTextVars += '{';
            WriteToGlbTextVar('action', 'CREATEGROUP', 0, TRUE);
            GlbTextVars += '"data" : [';
            MultipleVehicleEWayBill.Reset();
            MultipleVehicleEWayBill.SetRange("LFS Document No. ", ShipmentNo);
            if MultipleVehicleEWayBill.FindSet() then
                repeat
                    TotalCount := MultipleVehicleEWayBill.Count;
                    GlbTextVars += '{';
                    Location.Reset();
                    Location.GET(PostedTransferShipment."Transfer-from Code");
                    WriteToGlbTextVar('Generator_Gstin', Location."GST Registration No.", 0, TRUE);
                    WriteToGlbTextVar('EwbNo', PostedTransferShipment."E-Way Bill No.", 0, TRUE);
                    WriteToGlbTextVar('Reason', 'First Time', 0, TRUE);
                    WriteToGlbTextVar('Remarks', PostedTransferShipment."LFS E-Way Bill Remarks", 0, true);
                    Location.Reset();
                    Location.SetRange(Code, PostedTransferShipment."Transfer-from Code");
                    if Location.FindFirst() then begin
                        WriteToGlbTextVar('FromPlace', Location.City, 0, true);
                        State.Reset();
                        State.SetRange(Code, Location."State Code");
                        if State.FindFirst() then
                            WriteToGlbTextVar('FromState', State.Description, 0, true);
                    end;
                    if PostedTransferShipment."Transfer-to Code" <> '' then begin
                        Location.Reset();
                        Location.SetRange(Code, PostedTransferShipment."Transfer-to Code");
                        if Location.FindFirst() then begin
                            WriteToGlbTextVar('ToPlace', Location.City, 0, true);
                            State.Reset();
                            State.SetRange(Code, Location."State Code");
                            if State.FindFirst() then
                                WriteToGlbTextVar('ToState', State.Description, 0, true);
                        end;
                    end;

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
                    // WriteToGlbTextVar('TransportMode', Format(PostedSalesInvoice."LFS Mode of Transport"), 0, true);

                    WriteToGlbTextVar('TotalQuantity', Format(MultipleVehicleEWayBill."LFS Total Quantity"), 0, true);
                    WriteToGlbTextVar('UOM', MultipleVehicleEWayBill."LFS Unit of Measure", 0, false);
                    Increment += 1;
                    if TotalCount > Increment then
                        GlbTextVars += '},'
                    else
                        GlbTextVars += '}'

                until MultipleVehicleEWayBill.Next() = 0;
            GlbTextVars += ']}';
            Message(GlbTextVars);
            Location.Reset();
            Location.Get(PostedTransferShipment."Transfer-from Code");
            GenerateMultipleVehicleEWAYBILL(GlbTextVars, Location."GST Registration No.", PostedTransferShipment."No.");
        end;
    end;

    procedure AddVehicleDetailsTransferShipmentDetails(ShipmentNo: Code[20])
    var
        PostedTransferShipment: Record "Transfer Shipment Header";
        Location: Record Location;
        MultipleVehicleEWayBill: Record "LFS Multiple Vehicle E-WayBill";
        TotalCount: Integer;
        Increment: Integer;
    begin
        PostedTransferShipment.Reset();
        PostedTransferShipment.SetRange("No.", ShipmentNo);
        if PostedTransferShipment.FindFirst() then begin
            GlbTextVars := '';
            GlbTextVars += '{';
            WriteToGlbTextVar('action', 'MUTIVEHICLEADD', 0, TRUE);
            GlbTextVars += '"data" : [';
            MultipleVehicleEWayBill.Reset();
            MultipleVehicleEWayBill.SetRange("LFS Document No. ", ShipmentNo);
            if MultipleVehicleEWayBill.FindSet() then
                repeat
                    TotalCount := MultipleVehicleEWayBill.Count;
                    GlbTextVars += '{';
                    Location.Get(PostedTransferShipment."Transfer-from Code");
                    WriteToGlbTextVar('GENERATOR_GSTIN', Location."GST Registration No.", 0, TRUE);
                    WriteToGlbTextVar('EwbNo', PostedTransferShipment."E-Way Bill No.", 0, TRUE);
                    WriteToGlbTextVar('GroupNo', Format(MultipleVehicleEWayBill."LFS Group No."), 0, TRUE);
                    WriteToGlbTextVar('VehicleNo', MultipleVehicleEWayBill."LFS New Vehicle No.", 0, true);
                    WriteToGlbTextVar('TransDocDate', '', 0, true);
                    WriteToGlbTextVar('TransDocNumber', '', 0, true);
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
                    // WriteToGlbTextVar('TransportMode', Format(PostedSalesInvoice."LFS Mode of Transport"), 0, true);
                    WriteToGlbTextVar('Quantity', Format(MultipleVehicleEWayBill."LFS Total Quantity"), 0, false);

                    Increment += 1;
                    if TotalCount > Increment then
                        GlbTextVars += '},'
                    else
                        GlbTextVars += '}'

                until MultipleVehicleEWayBill.Next() = 0;
            GlbTextVars += ']}';
            Message(GlbTextVars);
            AddMultipleVehicleEWAYBILL(GlbTextVars, Location."GST Registration No.", PostedTransferShipment."No.");
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
