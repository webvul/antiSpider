function loghtml(txt){
    return
}
$(function(){
    var getKeyTime = new Date().getTime(),
        checkUrl = 'http://irondome.ly.com/td/check?_tdcheck=1',
        tdUrl = 'http://irondome.ly.com/anitservice/AntiStatus.ashx';
    $.td(function(){
        $.ajax({
            url: checkUrl,
            dataType: "jsonp",
            timeout:5000,
            error:function(){
                var nTime = new Date().getTime() - getKeyTime;
                loghtml('check-error');
                recordInfo('typ=6&chkr=2&rdyt=' + nTime);
            },
            fn: function(data) {
                var nTime = new Date().getTime() - getKeyTime;
                if(data[0] == '1'){
                    loghtml('check-1');
                    recordInfo('typ=8&chkr=1&rdyt=' + nTime);
                }else{
                    loghtml('check-0');
                    recordInfo('typ=7&chkr=2&rdyt=' + nTime);
                }
            }
        });
    });

    function recordInfo(data){
        $.ajax({
            url: tdUrl,
            data: data,
            dataType: 'jsonp'
        });
    }

});