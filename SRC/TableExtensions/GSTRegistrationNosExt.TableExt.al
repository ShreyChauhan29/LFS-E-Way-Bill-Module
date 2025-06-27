namespace LFSEWayBillModule.LFSEWayBillModule;

using Microsoft.Finance.GST.Base;

tableextension 73100 "LFS GST Registration Nos. Ext." extends "GST Registration Nos."
{
    fields
    {
        field(73100; "LFS E-Way Bill APIClientSecret"; Text[100])
        {
            Caption = 'E-Way Bill via IRN Client Secret';
            DataClassification = CustomerContent;
        }
        field(73101; "LFS E-Way Bill/Invoice API URL"; Text[100])
        {
            Caption = 'E-Way Bill via IRN API URL';
            DataClassification = CustomerContent;
        }
        field(73102; "LFS E-Way Bill API UserName"; Text[100])
        {
            Caption = 'E-Way Bill API UserName';
            DataClassification = CustomerContent;
        }
        field(73103; "LFS E-Way Bill API Password"; Text[100])
        {
            Caption = 'E-Way Bill API Password';
            DataClassification = CustomerContent;
        }
        field(73104; "LFS E-Way Bill API IP Address"; Text[100])
        {
            Caption = 'E-Way Bill via IRN IP Address';
            DataClassification = CustomerContent;
        }
        field(73105; "LFS E-Way Bill API ClientID"; Text[100])
        {
            Caption = 'E-Way Bill via IRN Client ID';
            DataClassification = CustomerContent;
        }
        field(73106; "LFS E-Way Bill PrivateKey"; Text[30])
        {
            Caption = 'E-Way Bill Private Key';
            DataClassification = CustomerContent;
        }
        field(73107; "LFS E-Way Bill PrivateValue"; Text[30])
        {
            Caption = 'E-Way Bill Private Value';
            DataClassification = CustomerContent;
        }
        field(73108; "LFS E-Way Bill API URL"; Text[100])
        {
            Caption = 'E-Way Bill API URL';
            DataClassification = CustomerContent;
        }
        field(73109; "LFS E-Way Bill AuthenticateURL"; Text[100])
        {
            Caption = 'E-Way Bill via IRN Authenticate URL';
            DataClassification = CustomerContent;
        }
        field(73110; "LFS E-Way Bill IP Address"; Text[100])
        {
            Caption = 'E-Way Bill IP Address';
            DataClassification = CustomerContent;
        }
    }
}
