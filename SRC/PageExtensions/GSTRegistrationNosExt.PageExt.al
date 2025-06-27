namespace LFSEWayBillModule.LFSEWayBillModule;

using Microsoft.Finance.GST.Base;

pageextension 73100 "LFS GST Registration Nos. Ext." extends "GST Registration Nos."
{
    layout
    {
        addafter("Input Service Distributor")
        {
            field("LFS E-Way Bill API UserName"; Rec."LFS E-Way Bill API UserName")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Common E-Way Bill API UserName field.', Comment = '%';
            }
            field("LFS E-Way Bill API Password"; Rec."LFS E-Way Bill API Password")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Common E-Way Bill API Password field.', Comment = '%';
            }
            field("LFS E-Way Bill PrivateKey"; Rec."LFS E-Way Bill PrivateKey")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Common E-Way Bill Private Key field.', Comment = '%';
            }
            field("LFS E-Way Bill PrivateValue"; Rec."LFS E-Way Bill PrivateValue")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Common E-Way Bill Private Value field.', Comment = '%';
            }
            field("LFS E-Way Bill API URL"; Rec."LFS E-Way Bill API URL")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the E-Way Bill API URL field.', Comment = '%';
            }
            field("LFS E-Way Bill IP Address"; Rec."LFS E-Way Bill IP Address")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the E-Way Bill IP Address field.', Comment = '%';
            }
            field("LFS E-Way Bill API ClientID"; Rec."LFS E-Way Bill API ClientID")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the E-Way Bill API Client ID field.', Comment = '%';
            }
            field("LFS E-Way Bill APIClientSecret"; Rec."LFS E-Way Bill APIClientSecret")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the E-Way Bill API Client Secret field.', Comment = '%';
            }
            field("LFS E-Way Bill API IP Address"; Rec."LFS E-Way Bill API IP Address")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the E-Way Bill API IP Address field.', Comment = '%';
            }
            field("LFS E-Way Bill AuthenticateURL"; Rec."LFS E-Way Bill AuthenticateURL")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the E-Way Bill Authenticate URL field.', Comment = '%';
            }
            field("LFS E-Way Bill/Invoice API URL"; Rec."LFS E-Way Bill/Invoice API URL")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the E-Way Bill API URL field.', Comment = '%';
            }
        }
    }
}
