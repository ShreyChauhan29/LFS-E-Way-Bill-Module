namespace LFSEWayBillModule.LFSEWayBillModule;

using Microsoft.Sales.Document;

pageextension 73102 "LFS Sales Order Ext." extends "Sales Order"
{
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
        modify("Mode of Transport")
        {
            Visible = false;
        }
    }
}
