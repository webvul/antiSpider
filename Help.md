#铁穹接入指南

##接入前准备：

1、需要将受保护接口调整为jsonp的ajax接口（所以不支持POST方式）

2、需要给出前端接口地址url对应的后端服务器ip列表，例如：

	ajax接口地址url为：
	
	http://dujia.ly.com/dujia/AjaxCallTravel.aspx?type=GetToursCommentSummary
	
	对应后端ip列表为：
	
	server   172.16.2.70:805 weight=5;
    server   172.16.2.71:805 weight=5;
    server   172.16.2.204:805 weight=6;
    server   172.16.2.251:805 weight=6;
    server   172.16.3.162:805 weight=6;
    server   172.16.3.163:805 weight=6;
    server   172.16.3.236:805 weight=1;
    server   172.16.8.21:805 weight=1;
    server   172.16.8.23:805 weight=1;
	
3、根据项目名称，需要将二级域名归类到统一的路径下，例如：

	原来完整的ajax请求地址为：
	
	http://gny.ly.com/tours/GetSameTitleHotSaleLines
	
	调整后的请求地址为（前端请求地址必须修改，后端也最好修改下，不改的话需要铁穹进行url改写）:
	
	http://irondome.ly.com/gny/tours/GetSameTitleHotSaleLines
	
	
##接入方式：

1、在页面加载铁穹sdk，请加载在jquery之后

	<script type="text/javascript" src="http://js.40017.cn/cn/c/zt/2015/0428/jquery-1.8.0.js"></script>
	<script type="text/javascript" src="http://js.40017.cn/cn/c/c/td/jq-td-all.js"></script>
	
2、将原来需要ajax的前端代码修改为jsonp方式，并放在铁穹ready事件回掉函数中，例如：
	
	$.td(function(){
		$.ajax({
				url: 'http://irondome.ly.com/gny/tours/GetSameTitleHotSaleLines',
				dataType: 'jsonp',
				timeout:1000,
				error:function(){
					//occur error
				},
				success: function(data) {
					//request success
				}
		});
	});
	
##注意事项：

1、本地调试请使用127.0.0.1这个ip打开页面或接口，已经加入到白名单，其他ip地址可能无法正常访问

2、目前接入域名限制为ly.com和tongcheng.com，其他域名需要接入请联系我

3、目前单设备限制频率为：

	10秒访问20次
	30秒访问30次
	50秒访问40次
	60秒访问45次
	
达到阈值将被拉到黑名单1分钟

	