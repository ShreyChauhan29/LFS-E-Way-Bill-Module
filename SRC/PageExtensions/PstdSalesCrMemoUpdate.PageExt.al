namespace LFSEWayBillModule.LFSEWayBillModule;

using Microsoft.Sales.History;

pageextension 73101 "LFSPstd. Sales Cr. Memo Update" extends "Pstd. Sales Cr. Memo - Update"
{
    layout
    {
        addafter(Payment)
        {
            group("LFS E-Way Bill")
            {
                Caption = 'E-Way Bill Details';
                field("Vehicle No."; Rec."Vehicle No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vehicle number on the sales document.';
                }
                field("Vehicle Type"; Rec."Vehicle Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vehicle type on the sales document. For example, Regular/ODC.';
                }
                field("LFS Mode of Transport"; Rec."LFS Mode of Transport")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the LFS Mode of Transport field.', Comment = '%';
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
                field("LFS E-Way Bill Cancel Reason"; Rec."LFS E-Way Bill Cancel Reason")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the E-Way Bill Cancel Reason field.', Comment = '%';
                }
                field("LFS E-Way Bill Cancel Remark"; Rec."LFS E-Way Bill Cancel Remark")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the E-Way Bill Cancel Remark field.', Comment = '%';
                }
            }
            part("LFS Multiple Vehicle E-WayBill"; "LFS Multiple Vehicle E-WayBill")
            {
                SubPageLink = "LFS Document No. " = field("No.");
                ApplicationArea = All;
                Caption = 'Multiple Vehicle E-Way Bill';
            }
        }
        movebefore("Vehicle No."; "Shipping Agent Code")
        modify("Shipping Agent Code")
        {
            Caption = 'Shipping Agent';
        }
    }
}
