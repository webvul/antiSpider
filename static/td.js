(function (win, doc) {
        // 'http://irondome.ly.com/anitservice/AntiStatus.ashx'
        // http://irondome.ly.com/td/key
        // http://irondome.ly.com/td/cookie
    var isReady = false,
        tdUrl = String.fromCharCode(104, 116, 116, 112, 58, 47, 47, 105, 114, 111, 110, 100, 111, 109, 101, 46, 108, 121, 46, 99, 111, 109, 47, 97, 110, 105, 116, 115, 101, 114, 118, 105, 99, 101, 47, 65, 110, 116, 105, 83, 116, 97, 116, 117, 115, 46, 97, 115, 104, 120 ),
        getKeyUrl = String.fromCharCode(104,116,116,112,58,47,47,105,114,111,110,100,111,109,101,46,108,121,46,99,111,109,47,116,100,47,107,101,121),
        cookieUrl = String.fromCharCode(104, 116, 116, 112, 58, 47, 47, 105, 114, 111, 110, 100, 111, 109, 101, 46, 108, 121, 46, 99, 111, 109, 47, 116, 100, 47, 99, 111, 111, 107, 105, 101),
        fns = [],
        errorType = [];
    fish.td = function (fn) {
        
        if (isReady) {
            fn();
        } else {
            fns.push(fn);
        }
    }
    function did(data) {
        fish.ajax({
            url: tdUrl,
            data: data,
            type: 'jsonp'
        });
    }

    function doFn() {
        for (var i = 0, len = fns.length; i < len; i++) {
            fns[i]();
        }
        isReady = true;
        fns = [];
    }
    
    (function(){
        //启动测试
        if (win === undefined || doc === undefined) {
            return;
        }
        
        if (doc.cookie === undefined) {
            errorType.push(1)
            did('typ1=4&typ2=1');
            return;
        }
        var times = 0,
            item = win.screen;
        if (!item || item.width <= 0 || item.height <= 0 || item.width >= 10000 || item.height >= 10000) {
            errorType.push(2)
            times++;
        }

        if(doc.body){
            if(doc.body.scrollHeight === 0){
                times++;
                errorType.push(3)
            }
        }else if(doc.documentElement){
            if(doc.documentElement.scrollHeight === 0){
                times++;
                errorType.push(3)
            }
        }else{
           times++;
           errorType.push(3)
        }
        try{
            var testDiv = doc.createElement('div');
            doc.body.appendChild(testDiv);
            testDiv.style.display = 'none';
            doc.body.removeChild(testDiv);
            testDiv = null;
        }catch(e){
            times++;
            errorType.push(4)
        }

        var ua = navigator.userAgent.toLowerCase(),
            browser = fish.browser();

        if(ua.match('msie')){
            if(win.ActiveXObject){
                try{
                    var xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
                    if(!xmlhttp){
                        times++;
                        errorType.push(5)
                    }
                }catch(e){
                    times++;
                    errorType.push(5)
                }
            }else{
                times++;
                errorType.push(5)
            }
        }
    
        if((browser.name == 'msie' && browser.version > 8) || (browser.name == 'moz' && browser.version > 8) || (browser.name == 'webkit' && browser.version > 15) || (browser.name == 'o' && browser.version > 11.5)){
            if(navigator.appName.toLowerCase() === "netscape"){
                if(!win.localStorage){
                    times++;
                    errorType.push(6)
                    return;
                }
                try{
                    document.createElement('canvas').getContext('2d');  
                }catch(e){
                    errorType.push(6)
                    times++;
                }
            }
        }
        
        //检测完毕，发送错误报告
        if (times >= 3) {
            var errstr = errorType.join(',');
            errstr = errstr ? errstr : 0;
            did('typ1=4&typ2='+ errstr);
            return;
        }
    })();

	
	var getKey = function(cb, times){
		var cb = cb || function(){};
		var times = times || 0;
		fish.ajax({
            url: getKeyUrl,
            type: "jsonp",
            timeout:2000,
            err:function(){
				if(times >= 2){
					cb('err')
				}else{
					getKey(cb,++times)
				}          
            },
            fn: function(data) {
				cb(null, data)
			}
        });
	};
	
	var getCookie = function(encrypted, cb, times){
		var cb = cb || function(){};
		var times = times || 0;
		
		fish.ajax({
			url: cookieUrl,
			data: "did=" + encodeURIComponent(encrypted.toString()),
			type: 'jsonp',
			timeout:2000,
			fn: function () {
				cb()
			},
			err: function () {
				if(times >= 2){
					cb('err')
				}else{
					getCookie(encrypted, cb, ++times)
				}  
			}
		});
	};
	
	
    (function(){
        var tq = fish.cookie.get('t_q');
        if (tq) {
            doFn();
            return;
        }
		
        var getKeyTime = new Date().getTime();
		getKey(function(err, data){
			var nTime = new Date().getTime() - getKeyTime;
			if(err){
				return did('typ=2&rdyt=' + nTime);
			}
			var key = data[0],
				iv = data[1],
				aesStr = data[2];
			if (key === "" || iv === "" || aesStr === "") {
				did('typ=3&rdyt=' + nTime);
			}
			try{
				key = CryptoJS.MD5(key);
				iv = CryptoJS.MD5(iv);
				encrypted = CryptoJS.AES.encrypt(aesStr, key, {iv: iv});
			}catch(e){
				return did('typ=5&rdyt=' + nTime);
			}
		
			getCookie(encrypted, function(err){
				var nTime = new Date().getTime() - getKeyTime;
				if(err){
					return did('typ=9&rdyt=' + nTime);
				}
				did('typ=0&rdyt=' + nTime);
				fish.cookie.set({name:'t_q',value: "1", path: '/' });
				doFn();
			})
		})
		
		
		
    })();
})(window, document);
