<script type="text/javascript" language="javascript">
function open_win(args)
{
    var url    = args;
    var now    = new Date();
    var name   = now.getTime();
    var Width  = 630;
    var Height = 420;
    param = "toolbar=no,location=no,status=yes,scrollbars=yes,resizable=yes,width=" + Width + ",height=" + Height + ",left=0,top=0";
    eval("name = window.open(url, name, param)");
    if (!eval("name.opener")) {
        eval("name.opener = self");
    }
}
</script>
