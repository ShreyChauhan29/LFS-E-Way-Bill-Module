namespace LFSEWayBillModule.LFSEWayBillModule;
using Microsoft.Foundation.UOM;
table 73100 "LFS Multiple Vehicle E-WayBill"
{
    Caption = 'Multiple Vehicle E-Way Bill';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "LFS Document No. "; Code[20])
        {
            Caption = 'Document No. ';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2; "LFS Line No."; Integer)
        {
            Caption = 'Line No.';
            AutoIncrement = true;
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(3; "LFS New Vehicle No."; Code[20])
        {
            Caption = 'New Vehicle No.';
            DataClassification = CustomerContent;
        }
        field(4; "LFS Old Vehicle No."; Code[20])
        {
            Caption = 'Old Vehicle No.';
            DataClassification = CustomerContent;
        }
        field(5; "LFS Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure';
            TableRelation = "Unit of Measure".Code;
            DataClassification = CustomerContent;
        }
        field(6; "LFS Group No."; Integer)
        {
            Caption = 'Group No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7; "LFS Total Quantity"; Decimal)
        {
            Caption = 'Total Quantity';
            DataClassification = CustomerContent;
        }
        field(8; "LFS Vehicle Added Date"; DateTime)
        {
            Caption = 'Vehicle Added Date';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; "LFS Document No. ", "LFS Line No.", "LFS Group No.")
        {
            Clustered = true;
        }
    }
}
