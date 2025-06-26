namespace GeneratedPermission1;

using LFSEWayBillModule.LFSEWayBillModule;

permissionset 73100 GeneratedPermission1
{
    Assignable = true;
    Permissions = codeunit "E-Way Bill Generation" = X,
        tabledata "LFS Multiple Vehicle E-WayBill" = RIMD,
        table "LFS Multiple Vehicle E-WayBill" = X,
        codeunit "LFS E-Way Bill Cancellation" = X,
        codeunit "LFS E-Way Bill Update Part-B" = X,
        codeunit "LFS EventsSubscriber" = X,
        codeunit "LFS EWay Bill Updt Transporter" = X,
        codeunit "LFS Multi Vehicle UpdatePart-B" = X,
        codeunit "LFS Multiple Vehicle E-WayBill" = X,
        page "LFS Multiple Vehicle E-WayBill" = X;
}