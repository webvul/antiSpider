function loghtml(txt){
    return
}
fish.ready(function(){
    var getKeyTime = new Date().getTime(),
        checkUrl = 'http://irondome.ly.com/td/check?_tdcheck=1',
        tdUrl = 'http://irondome.ly.com/anitservice/AntiStatus.ashx';
    fish.td(function(){
        fish.ajax({
            url: checkUrl,
            type: "jsonp",
            timeout:1000,
            err:function(){
                var nTime = new Date().getTime() - getKeyTime;
                loghtml('check-error')
                recordInfo('typ=6&chkr=2&rdyt=' + nTime);
            },
            fn: function(data) {
                var nTime = new Date().getTime() - getKeyTime;
                if(data[0] == '1'){
                    loghtml('check-1')
                    recordInfo('typ=8&chkr=1&rdyt=' + nTime);
                }else{
                    loghtml('check-0')
                    recordInfo('typ=7&chkr=2&rdyt=' + nTime);
                }
            }
        });
    })

    function recordInfo(data){
        fish.ajax({
            url: tdUrl,
            data: data,
            type: 'jsonp'
        });
    }

});