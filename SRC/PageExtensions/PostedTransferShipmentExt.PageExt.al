namespace LFSEWayBillModule.LFSEWayBillModule;

using Microsoft.Inventory.Transfer;

pageextension 73108 "LFSPosted Transfer ShipmentExt" extends "Posted Transfer Shipment"
{
    PromotedActionCategories = 'New, Process, Report, Category4, Category5, Category6, Category7, Category8, Category9, E-Way Bill';
    layout
    {
        addafter("Mode of Transport")
        {
            field("LFS Mode of Transport"; Rec."LFS Mode of Transport")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the LFS Mode of Transport field.', Comment = '%';
            }
        }
        addafter("E-Way Bill No.")
        {
            field("LFS E-Way Bill Date"; Rec."LFS E-Way Bill Date")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the LFS E-Way Bill Date field.', Comment = '%';
            }
            field("LFS E-Way Bill Valid Upto Date"; Rec."LFS E-Way Bill Valid Upto Date")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the LFS E-Way Bill Valid Upto Date field.', Comment = '%';
            }
            field("LFS E-Way Bill VehicleUpdtDate"; Rec."LFS E-Way Bill VehicleUpdtDate")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the E-Way Bill Vehicle Updated Date field.', Comment = '%';
            }
            field("LFS E-Way Bill TransporterDate"; Rec."LFS E-Way Bill TransporterDate")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the E-Way Bill Transporter Updated Date field.', Comment = '%';
            }
            field("LFS E-Way Bill Vehicle Reason"; Rec."LFS E-Way Bill Vehicle Reason")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the E-Way Bill Vehicle Reason field.', Comment = '%';
            }
            field("LFS E-Way Bill Remarks"; Rec."LFS E-Way Bill Remarks")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the E-Way Bill Remarks field.', Comment = '%';
            }
            field("LFS E-Way Bill Message"; Rec."LFS E-Way Bill Message")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the LFS E-Way Bill Message field.', Comment = '%';
            }
        }
        modify("Mode of Transport")
        {
            Visible = false;
        }
    }
    actions
    {
        addafter("&Shipment")
        {
            group("E-Way Bill")
            {
                Caption = 'E-Way Bill';
                action("LFS Generate E-Way Bill")
                {
                    ApplicationArea = All;
                    Caption = 'Generate E-Way Bill';
                    ToolTip = 'Specifies the Generate E-Way Bill';
                    Image = RegisteredDocs;
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        EInvoiceAPI: Codeunit "E-Way Bill Generation";
                    begin
                        if Rec."IRN Hash" <> '' then begin
                            Clear(EInvoiceAPI);
                            EInvoiceAPI.GenerateTransferShipmentDetails(Rec."No.");
                        end;
                    end;
                }
                action("LFS Update E-Way Bill Part B")
                {
                    ApplicationArea = All;
                    Caption = 'Update E-Way Bill Part B';
                    ToolTip = 'Specifies the Update E-Way Bill Part B';
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedIsBig = true;
                    Image = UpdateDescription;
                    trigger OnAction()
                    var
                        UpdatePartB: Codeunit "LFS E-Way Bill Update Part-B";
                    begin
                        if (Rec."IRN Hash" <> '') AND (Rec."E-Way Bill No." <> '') then begin
                            Clear(UpdatePartB);
                            UpdatePartB.GenerateTransferShipmentDetails(Rec."No.");
                        end;
                    end;
                }
                action("LFS Update E-Way Bill Transporter")
                {
                    ApplicationArea = All;
                    Caption = 'Update E-Way Bill Transporter';
                    ToolTip = 'Specifies the Update E-Way Bill Transporter';
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedIsBig = true;
                    Image = UpdateDescription;
                    trigger OnAction()
                    var
                        UpdateTransporter: Codeunit "LFS EWay Bill Updt Transporter";
                    begin
                        if (Rec."IRN Hash" <> '') AND (Rec."E-Way Bill No." <> '') AND (Rec."Shipping Agent Code" <> '') then begin
                            Clear(UpdateTransporter);
                            UpdateTransporter.GenerateTransferShipmentDetails(Rec."No.");
                        end;
                    end;
                }
                action("LFS Cancel E-Way Bill No.")
                {
                    ApplicationArea = All;
                    Caption = 'Cancel E-Way Bill No.';
                    ToolTip = 'Specifies the Cancel E-Way Bill No.';
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedIsBig = true;
                    Image = Cancel;
                    trigger OnAction()
                    var
                        EInvoiceAPI: Codeunit "E-Way Bill Generation";
                    begin
                        Clear(EInvoiceAPI);
                        // EInvoiceAPI.CancelIRN(Rec."No.",1,Rec."Location GST Reg. No.",Rec."Cancel Reason");
                    end;
                }
                action("LFS Get E-Way Bill By Invoice No.")
                {
                    ApplicationArea = All;
                    Caption = 'Get E-Way Bill By Invoice No.';
                    ToolTip = 'Specifies the Get E-Way Bill By Invoice No.';
                    Image = GetSourceDoc;
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        EInvoiceAPI: Codeunit "E-Way Bill Generation";
                    begin
                        Clear(EInvoiceAPI);
                        // EInvoiceAPI.FetchIRN(Rec."No.", 1, Rec."Posting Date", Rec."Location GST Reg. No.");
                    end;
                }
                action("LFS Cancel Eway Bill")
                {
                    Image = CancelAllLines;
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedIsBig = true;
                    ToolTip = 'Specifies the Cancel Eway Bill';
                    Caption = 'Cancel E-Way Bill No.';
                    trigger OnAction()
                    var
                        EWayBillAPI: Codeunit "LFS E-Way Bill Cancellation";
                    begin
                        CLEAR(EwayBillAPI);
                        EwayBillAPI.GenerateCancelEwayBillTransferShipment(Rec."No.");
                    end;
                }
                action("LFS Download Eway Bill PDF")
                {
                    Image = Download;
                    ToolTip = 'Specifies the Download Eway Bill PDF';
                    Caption = 'Download E-Way Bill PDF';
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedIsBig = true;
                    trigger OnAction()
                    var
                        EWayBillAPI: Codeunit "E-Way Bill Generation";
                    begin
                        CLEAR(EwayBillAPI);
                        EwayBillAPI.DownloadEwayBillPDFTransferShipments(Rec."No.");
                    end;
                }
            }
        }
    }
}