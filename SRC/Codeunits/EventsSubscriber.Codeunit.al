namespace LFSEWayBillModule.LFSEWayBillModule;
using Microsoft.Sales.History;

codeunit 73102 "LFS EventsSubscriber"
{
    Permissions = tabledata "Sales Invoice Header" = RM;

    [EventSubscriber(ObjectType::Page, Page::"Posted Sales Inv. - Update", OnAfterRecordChanged, '', false, false)]
    local procedure "Posted Sales Inv. - Update_OnAfterRecordChanged"(var SalesInvoiceHeader: Record "Sales Invoice Header"; xSalesInvoiceHeader: Record "Sales Invoice Header"; var IsChanged: Boolean)
    begin
        IsChanged :=
            (SalesInvoiceHeader."Vehicle No." <> xSalesInvoiceHeader."Vehicle No.") or
            (SalesInvoiceHeader."Vehicle Type" <> xSalesInvoiceHeader."Vehicle Type") or
            (SalesInvoiceHeader."LFS Mode of Transport" <> xSalesInvoiceHeader."LFS Mode of Transport") or
            (SalesInvoiceHeader."LFS E-Way Bill Vehicle Reason" <> xSalesInvoiceHeader."LFS E-Way Bill Vehicle Reason") or
            (SalesInvoiceHeader."LFS E-Way Bill Remarks" <> xSalesInvoiceHeader."LFS E-Way Bill Remarks") or
            (SalesInvoiceHeader."LFS E-Way Bill Cancel Reason" <> xSalesInvoiceHeader."LFS E-Way Bill Cancel Reason") or
            (SalesInvoiceHeader."LFS E-Way Bill Cancel Remark" <> xSalesInvoiceHeader."LFS E-Way Bill Cancel Remark");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Inv. Header - Edit", OnRunOnBeforeAssignValues, '', false, false)]
    local procedure "Sales Inv. Header - Edit_OnRunOnBeforeAssignValues"(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceHeaderRec: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader.Validate("Vehicle No.", SalesInvoiceHeaderRec."Vehicle No.");
        SalesInvoiceHeader.Validate("Vehicle Type", SalesInvoiceHeaderRec."Vehicle Type");
        SalesInvoiceHeader.Validate("LFS Mode of Transport", SalesInvoiceHeaderRec."LFS Mode of Transport");
        SalesInvoiceHeader.Validate("LFS E-Way Bill Vehicle Reason", SalesInvoiceHeaderRec."LFS E-Way Bill Vehicle Reason");
        SalesInvoiceHeader.Validate("LFS E-Way Bill Remarks", SalesInvoiceHeaderRec."LFS E-Way Bill Remarks");
        SalesInvoiceHeader.Validate("LFS E-Way Bill Cancel Reason", SalesInvoiceHeaderRec."LFS E-Way Bill Cancel Reason");
        SalesInvoiceHeader.Validate("LFS E-Way Bill Cancel Remark", SalesInvoiceHeaderRec."LFS E-Way Bill Cancel Remark");
        SalesInvoiceHeader.Modify();
    end;

}
