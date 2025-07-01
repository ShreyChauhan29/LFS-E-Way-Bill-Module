namespace LFSEWayBillModule.LFSEWayBillModule;

using Microsoft.Sales.Document;

tableextension 73101 "LFS Sales Header Ext." extends "Sales Header"
{
    fields
    {
        field(73100; "LFS Mode of Transport"; Enum "LFS Mode of Transports")
        {
            Caption = 'Mode of Transport';
            DataClassification = CustomerContent;
        }
        field(73101; "LFS E-Way Bill Date"; Text[20])
        {
            Caption = 'E-Way Bill Date';
            DataClassification = CustomerContent;
        }
        field(73102; "LFS E-Way Bill Valid Upto Date"; Text[20])
        {
            Caption = 'E-Way Bill Valid Upto Date';
            DataClassification = CustomerContent;
        }
        field(73103; "LFS E-Way Bill Message"; Blob)
        {
            Caption = 'E-Way Bill Message';
            DataClassification = CustomerContent;
        }
        field(73104; "LFS E-Way Bill Vehicle Reason"; Enum "LFS Vehicle Reason")
        {
            Caption = 'E-Way Bill Vehicle Reason';
            DataClassification = CustomerContent;
        }
        field(73105; "LFS E-Way Bill Remarks"; Text[500])
        {
            Caption = 'E-Way Bill Remarks';
            DataClassification = CustomerContent;
        }
        field(73106; "LFS E-Way Bill VehicleUpdtDate"; Text[20])
        {
            Caption = 'E-Way Bill Vehicle Updated Date';
            DataClassification = CustomerContent;
        }
        field(73107; "LFS E-Way Bill TransporterDate"; Text[20])
        {
            Caption = 'E-Way Bill Transporter Updated Date';
            DataClassification = CustomerContent;
        }
        field(73108; "LFS E-Way Bill Cancel Date"; Text[20])
        {
            Caption = 'E-Way Bill Cancel Date';
            DataClassification = CustomerContent;
        }
        field(73109; "LFS E-Way Bill Cancel Reason"; Enum "LFS Cancel Reason")
        {
            Caption = 'E-Way Bill Cancel Reason';
            DataClassification = CustomerContent;
        }
        field(73110; "LFS E-Way Bill Cancel Remark"; Text[500])
        {
            Caption = 'E-Way Bill Cancel Remark';
            DataClassification = CustomerContent;
        }
    }
}
