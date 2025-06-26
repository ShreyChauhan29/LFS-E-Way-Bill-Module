namespace LFSEWayBillModule.LFSEWayBillModule;

using Microsoft.Sales.Document;

pageextension 73103 "LFS Sales Invoice Ext." extends "Sales Invoice"
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
