namespace LFSEWayBillModule.LFSEWayBillModule;

enum 73102 "LFS Cancel Reason"
{
    Extensible = true;

    value(0; "0")
    {
        Caption = ' ';
    }
    value(1; "Duplicate")
    {
        Caption = 'Duplicate';
    }
    value(2; "Order Cancelled")
    {
        Caption = 'Order Cancelled';
    }
    value(3; "Data Entry Mistake")
    {
        Caption = 'Data Entry Mistake';
    }
    value(4; "Others")
    {
        Caption = 'Others';
    }
}
