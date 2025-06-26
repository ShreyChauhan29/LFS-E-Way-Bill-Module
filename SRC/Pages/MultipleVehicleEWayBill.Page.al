namespace LFSEWayBillModule.LFSEWayBillModule;

page 73100 "LFS Multiple Vehicle E-WayBill"
{
    ApplicationArea = All;
    Caption = 'Multiple Vehicle E-Way Bill List';
    PageType = ListPart;
    SourceTable = "LFS Multiple Vehicle E-WayBill";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("LFS Document No. "; Rec."LFS Document No. ")
                {
                    ToolTip = 'Specifies the value of the Document No. field.', Comment = '%';
                }
                field("LFS New Vehicle No."; Rec."LFS New Vehicle No.")
                {
                    ToolTip = 'Specifies the value of the New Vehicle No. field.', Comment = '%';
                }
                field("LFS Old Vehicle No."; Rec."LFS Old Vehicle No.")
                {
                    ToolTip = 'Specifies the value of the Old Vehicle No. field.', Comment = '%';
                }
                field("LFS Total Quantity"; Rec."LFS Total Quantity")
                {
                    ToolTip = 'Specifies the value of the Total Quantity field.', Comment = '%';
                }
                field("LFS Unit of Measure"; Rec."LFS Unit of Measure")
                {
                    ToolTip = 'Specifies the value of the Unit of Measure field.', Comment = '%';
                }
                field("LFS Group No."; Rec."LFS Group No.")
                {
                    ToolTip = 'Specifies the value of the Group No. field.', Comment = '%';
                }
            }
        }
    }
}
