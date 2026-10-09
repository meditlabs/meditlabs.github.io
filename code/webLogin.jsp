<%@taglib uri="darewayBS.tld" prefix="dw"%><%@page import="com.dareway.framework.util.*"%>
<%--
Independent entry: only add this JSP to the existing mhs5 application root.
Do not edit mainFrame.jsp or logonDialog.jsp. No userscript is required.
Open /mhs5/webLogin.jsp; successful login opens /mhs5/webLogin.jsp?view=main.
Save this JSP as GBK, matching the original application's static includes.
Existing initApplicationConstants.jsp, frameImportFile.jsp, importFile.jsp,
framework JS/CSS and tag libraries remain required, unchanged.
Default credentials are prefilled; submit after 5 seconds of inactivity. CAPTCHA is still required.
This entry embeds the configured credentials in its browser response; it does not write password cookies or storage.
Only known card-control alerts are suppressed. Dynamic CLodop script URLs
are rewritten; other child documents/static script URLs are not guaranteed.
If app authentication filters reject this new login/script entry, deployment
access configuration is required, using the same rules as the original login.
Device-auth modes use the original entry. Target WebLogic compilation and
real login/printing have not been tested. Back up WAR and update deployment.
--%>
<%@page import="com.dareway.service.util.Mhs5PubUtil"%><%@page language="java" contentType="text/html; charset=gbk" pageEncoding="GBK"%><%@page import="com.dareway.framework.appVersion.AppVersion"%><%@page import="com.dareway.framework.common.GlobalNames"%><%@page import="com.dareway.framework.util.CurrentUser"%><%@page import="com.dw.pub.GlobalPara"%><%@page session="false"%><%@page import="java.io.*" %><%@page import="com.dareway.framework.util.SecUtil" %>

<%
// The same JSP serves the compatibility script without running login initialization.
if ("compat".equals(request.getParameter("mode"))) {
    response.setContentType("application/javascript; charset=UTF-8");
    response.setHeader("Cache-Control", "no-store");
    out.write("(function () {\n    'use strict';\n    if (window.__dwBrowserCompatInstalled) return;\n    window.__dwBrowserCompatInstalled = true;\n    var originalAlert = window.alert;\n    // Only suppress the known card-control warning; preserve login/business errors.\n    window.alert = function (message) {\n        var text = String(message);\n        if (/\u65e0\u6cd5\u52a0\u8f7d\u8bfb\u5361\u5668\u63a7\u4ef6/.test(text)) {\n            console.info('[Browser compatibility] Card-control warning suppressed');\n            return;\n        }\n        return originalAlert.apply(window, arguments);\n    };\n    var nativeURL = window.URL;\n    var scriptSrc = Object.getOwnPropertyDescriptor(HTMLScriptElement.prototype, 'src');\n    var originalSetAttribute = Element.prototype.setAttribute;\n    function rewrite(value) {\n        var text = String(value);\n        try {\n            var url = new nativeURL(text, document.baseURI);\n            if (url.protocol === 'http:' && url.hostname === 'localhost' &&\n                (url.port === '8000' || url.port === '18000')) {\n                url.hostname = location.hostname;\n                return url.href;\n            }\n        } catch (e) { }\n        return text;\n    }\n    if (scriptSrc && scriptSrc.get && scriptSrc.set && scriptSrc.configurable) {\n        Object.defineProperty(HTMLScriptElement.prototype, 'src', {\n            configurable: scriptSrc.configurable,\n            enumerable: scriptSrc.enumerable,\n            get: scriptSrc.get,\n            set: function (value) { scriptSrc.set.call(this, rewrite(value)); }\n        });\n    }\n    Element.prototype.setAttribute = function (name, value) {\n        if (this.tagName === 'SCRIPT' && String(name).toLowerCase() === 'src') {\n            value = rewrite(value);\n        }\n        return originalSetAttribute.call(this, name, value);\n    };\n})();\n");
    return;
}
%>
<% if ("main".equals(request.getParameter("view"))) { %>

<%
boolean isUserExist = SessionUtil.isUserExist(request);
String usersessionuuid = request.getParameter("__usersession_uuid");
if (usersessionuuid == null) usersessionuuid = (String)request.getAttribute("__usersession_uuid");
if (!isUserExist) {
%>
<!DOCTYPE html><html><head><meta charset="gbk"><script>window.location.replace('webLogin.jsp');</script></head><body></body></html>
<% } else {
CurrentUser user = (CurrentUser)SessionUtil.getUser(request);
String yljglx = (String)user.getValue("yljglx");
String userid = (String)user.getUserid();
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="gbk">
<meta http-equiv="X-UA-Compatible" content="IE=Edge">
<link rel="icon" type="image/x-icon" href="dareway.ico">
<title><%= "2".equals(yljglx) ? "地纬定点药店结算平台" : "地纬智能医院服务平台" %></title>
<script src="<%=request.getContextPath()%>/webLogin.jsp?mode=compat&v=2"></script>
<%@include file="frameImportFile.jsp" %>
<%@include file="importFile.jsp" %>
</head>
<body class="dw-mainFrame">
<% if ("234,225".indexOf(GlobalPara.DBID) >= 0 && !"dwadmin".equalsIgnoreCase(userid)) { %>
<dw:laneContainer name="dw-laneContainer" showLaneSwitcher="false"></dw:laneContainer>
<% } else { %>
<dw:laneContainer name="dw-laneContainer"></dw:laneContainer>
<% } %>
<iframe name="download_hidden_frame" id="download_hidden_frame" style="display:none"></iframe>
<div style="height:0;width:0;overflow:hidden">
<OBJECT id="DWCardReader" type="application/x-qt-plugin" CLASSID="CLSID:DF7D3B36-B6A5-4064-8F44-6631C7F48126" CODEBASE="./DWCardReader/DWCardReader.cab#version=1,7,60,7" width="0" height="0"></OBJECT>
</div>
<% if ("105".indexOf(GlobalPara.DBID) >= 0) { %>
<div style="height:0;width:0;overflow:hidden"><OBJECT ID="FacePay" type="application/x-qt-plugin" CLASSID="CLSID:9D56CD2C-AEDB-4A38-93F4-4E8F34C37619" CODEBASE="./DWCardReader/DWFacePay.cab#version=1,0,1,8" width="0" height="0"></OBJECT></div>
<% } %>
<% if ("104,106,108".indexOf(GlobalPara.DBID) >= 0) { %>
<div style="height:0;width:0;overflow:hidden"><OBJECT ID="PosTrade" type="application/x-qt-plugin" CLASSID="CLSID:1BE3F9D7-183C-4DD0-AA64-F92A7563D981" CODEBASE="./DWCardReader/PosTrade.cab#version=1,1,7,5" width="0" height="0"></OBJECT></div>
<% } %>
<% if ("108".indexOf(GlobalPara.DBID) >= 0) { %>
<div style="height:0;width:0;overflow:hidden"><OBJECT ID="ocxobject" type="application/x-qt-plugin" CLASSID="CLSID:F74CFBA7-A1C0-410A-8381-35BBC3C9AE0D" CODEBASE="" width="0" height="0"></OBJECT></div>
<% } %>
<script>
function GetDWCardReaderActiveXObject() {
    var ele = document.getElementById('DWCardReader');
    return ele && ele.object != null ? ele : null;
}
var cardType = "<%=GlobalNames.CARD_TYPE%>";
if (cardType != null && cardType !== '') {
    LoadDWCardReaderClass('./DWCardReader');
    $(document).ready(function () {
        DWSetReaderList("<%=GlobalNames.CARD_TYPE%>".split(','));
    });
}
$(document).ready(function () {
    JSEManager.doJSInNewJSE(function () {
        GlobalNames.__usersession_uuid = '<%=usersessionuuid%>';
        var laneContainer = getLaneManager();
        if (!laneContainer) {
            alert('mainFrame:未在页面中检测到LaneManager组件，请检查!');
            return;
        }
        var mainLane = laneContainer.setMainLane({key:'mainLane'}, '主工作台');
        laneContainer.activeLane(mainLane.getID());
        mainLane.openBeacon('mainFrame', 'mainFrame', 'index.jsp');
    });
    // Retain the original application's session-exit behavior.
    window.onbeforeunload = function () {
        location.href = GlobalNames.compileURL('logoffController.do');
    };
});
</script>
</body></html>
<% } %>

<% } else { %>
<%
	String current_yybm =GlobalPara.CURRENT_YYBM;
	String current_version =AppVersion.getAppVersion();
	String zxsbjgbh = "";
 	String use_encryptionCard = GlobalPara.USE_EncryptionCard.toLowerCase();
	String sfkqdlyzm = Mhs5PubUtil.getPara(current_yybm, "sfkqdlyzm", "0");//是否开始登录动态验证码
	String display = "display: none;";
	if ("1".equals(sfkqdlyzm)) {
		display = "display: block;";
	}
 	//之前给莱芜做的需求，莱芜首页展示二维码，所以需要取zxsbjgbh，济南市级统筹后，莱芜不再是37120101，不再支持该需求
 	//针对东营、淄博、泰安使用前后端的地区，前端医院编码在前端的该文件中取，特殊配置见：deployPlugin.xml中的URLS_NOT_PROXY_TO_BE
 	//由于前端无法连接数据库，故注释该段代码，以后有特殊情况特殊实现@add by gy20191220
	/* if(current_yybm.length() > 6){
		zxsbjgbh = Mhs5PubUtil.getZxsbjgbh(current_yybm.substring(0, 6));
	} */

%> 


<%
if (GlobalNames.CA_LOGON_MODE || !"0".equals(GlobalNames.LOGON_MODE)
    || "true".equalsIgnoreCase(GlobalPara.USE_DUKEY)
    || "true".equalsIgnoreCase(GlobalPara.USE_EncryptionCard)) {
    response.setStatus(403);
    out.write("This browser entry supports password login only. Use the original device-authentication entry.");
    return;
}
%>

<!DOCTYPE html>
<html>
	<head>
<script src="<%=request.getContextPath()%>/webLogin.jsp?mode=compat&v=2"></script>
		<meta http-equiv="Content-Type" content="text/html; charset=gbk">
		<meta http-equiv="X-UA-Compatible" content="IE=Edge">
		<link rel="icon" href="dareway.ico" type="image/x-icon" />
		<link rel="shortcut icon" href="dareway.ico">
		<link rel="Bookmark" href="dareway.ico">
		<title>系统登录</title>
		<%
			String version = null;
			if(GlobalNames.DEBUGMODE == true){
				// 调试模式下，JS的时间戳是当前时间
				version = String.valueOf(System.currentTimeMillis()); 
			}else{
				// 非调试模式下，JS的时间戳是封板时间
				version = GlobalNames.FRAMEWORK_VERSION;
			}
		%>
		<link type="text/css" rel="stylesheet" href="./jsp/workflow/component/material/scan/pub/batchUploadFilePage.css?_=<%=version %>"/>
		<%@include file="jsp/initApplicationConstants.jsp" %>
		<%--先引入支撑框架运行的最小集合 --%>
		<link type="text/css" rel="stylesheet" href="./framework/themes/default/sef.min.css?_=<%=version %>">
        <script type="text/javaScript" charset="UTF-8" src='./framework/base/base.bundle.min.js?_=<%=version %>'></script>
        <script type="text/javascript" charset="UTF-8" src="./widgets/Utils.min.js?_=<%=version %>"></script>
        <script type="text/javaScript" charset="UTF-8" src='./framework/widgets/utils.bundle.min.js?_=<%=version %>'></script>
        <script type="text/javaScript" charset="UTF-8" src='./framework/widgets/layout/GlobalNames.js?_=<%=version %>'></script>
        <script type="text/javascript" charset="UTF-8" src="./framework/widgets/layout/requestSubmit.js?_=<%=version %>"></script>
        <script type="text/javascript" charset="UTF-8" src="./framework/widgets/layer/layer.js?_=<%=version %>"></script>
        <script type="text/javaScript" charset="UTF-8" src='./framework/devices/ukeys/ukeys.bundle.min.js?_=<%=version %>'></script>
        <%--引入UKEY相关的JS--%>
        <script type="text/javascript" charset="UTF-8" src="./framework/widgets/ca/Ca.js?_=<%=version %>"></script>
	    <script type="text/javascript" charset="UTF-8" src="./framework/widgets/nsca/NSCAUtil.js?_=<%=version %>"></script>
		<script type="text/javaScript" charset="UTF-8" src='./framework/widgets/wfca/WfCa.js?_=<%=version %>'></script>
		<script type="text/javaScript" charset="UTF-8" src='./framework/widgets/wnca/WnCa.js?_=<%=version %>'></script>
		<script type="text/javaScript" charset="UTF-8" src='./framework/widgets/nsFaceAndFingerVerify/NSFaceAndFingerVerify.js?_=<%=version %>'></script>		
		<script type="text/javaScript" charset="UTF-8" src='./framework/widgets/whca/WhCa.js?_=<%=version %>'></script>
		<script type="text/javaScript" charset="UTF-8" src='./framework/widgets/tzwyca/TzwyCa.js?_=<%=version %>'></script>
		<script type="text/javascript" src="./mhs5/javaScript/LiandiCardATLM35.js?_=<%=version %>"></script>
		<script type="text/javascript" src="./mhs5/javaScript/LiandiCardATL.js?_=<%=version %>"></script>
		<script type="text/javascript" src="./mhs5/javaScript/Mhs5ReadCardUtil.js?_=<%=version %>"></script>
		<script type="text/javascript" src="./mhs5/javaScript/SM4.js?_=<%=version %>"></script>
		<link type="text/css" rel="stylesheet" href="./css/logon.css">
	</head>
	<body>

		<%-- 背景图片 --%>
<%-- 		<% if("DWDS".equals(GlobalPara.APP_TYPE)){ %>
			<img class="dw-logon-bg" src="./images/logon/body_bg_dwds.jpg">			
	    <%}else{ %>
	    	<img class="dw-logon-bg" src="./images/logon/body_bg.jpg">
	    <%} %> --%>
	<%--     <% if("37120101".equals(zxsbjgbh)){%>	
	    	<img class="dw-logon-bg" src="./images/logon/body_bg3712.jpg">
	    <%}else{%> --%>
	    	<img class="dw-logon-bg" src="./images/logon/body_bg.jpg">
	    <%-- <%}%> --%>
		<% if("true".equals(GlobalPara.USE_DUKEY.toLowerCase())){%> 
			<OBJECT ID="FCOM" CLASSID="CLSID:91B81FB5-6FC3-497C-905D-430FA0D01EB7"
			codebase="framework/widgets/dukey/fmcom.cab#version=2,3,0,0"> </OBJECT>
			<div class="mhs5-logon-title" id="yymc">
			</div> 	
			<script type="text/javascript">
			var flag = 1;
			try{
				var dukeyid = checkdukey();
				var dukeyinfo = dUKeyUtil.getDUKeyInfo(dukeyid);
				if(dukeyinfo==null)
					throw new Error();
				var holdername = dukeyinfo.holdername;	
				var holderid = dukeyinfo.holderid;	
				var index = holderid.indexOf("-");
				var yybm = holderid.substring(index+1).trim();
				
			}catch(oE){
				flag = 0;
				document.getElementById("yymc").innerHTML ="DUKEY认证失败！";
			}
			if(flag==1){
				document.getElementById("yymc").innerHTML =holdername+"("+yybm+")";
				var czy = getCzybyDukey(dukeyid,yybm);
			}
			
			function checkdukey(){		
				var dukeyid = dUKeyUtil.checkCurrentDUKey();
				if(dukeyid==null)
					return;
				var challengeNumber = dUKeyUtil.getChallengeNumber(dukeyid);
				if(challengeNumber === null){
					return null;
				}
				var battleNumber = dUKeyUtil.getBattleNumber(dukeyid,challengeNumber);
				if(battleNumber === null){
					return null;
				}
				var rv = dUKeyUtil.assertDUKeyValid(dukeyid,battleNumber);
				if(rv==null)
					return;
				if(rv == "f"){
					throw new Error("DUKEY认证失败！"); 
				}
				return dukeyid;
			}
			
			function getCzybyDukey(dukeyid,yybm){
				var url= new URL("logon.do?method=getCzybyDukey");
				url.addPara("dukeyid", dukeyid);
				url.addPara("yybm", yybm);
				var result = AjaxUtil.ajaxRequest(url.getURLString());
				return result;
			}
						
			</script> 
	    <%}%>
	    
		<%-- 登录表单 --%>
	<% if(GlobalNames.CA_LOGON_MODE){ %>		
		<div class="dw-ca-logon-form"  style="top: 50%;right: 22%; margin-top: -220px;">
			<div style="top: 8%;left:50%;margin-left:-50px;position: absolute; font-size: 15px;font-family: 微软雅黑;color: #555555; text-align: center;">
     			<div style="width: 100px;">系统登录</div>
     		</div>
			<div id="yybmInput" class="dw-ca-logon-form-yybm" ></div>
			<div id="userNameInput" class="dw-ca-logon-form-loginname"></div>
			<input type="password" id="userPwdInput" class="dw-ca-logon-form-pwd" placeholder="请输入密码" autocomplete="off"/>
			<input type="button" id="logonBtn" class="dw-ca-logon-form-btnlogin" onclick="onLogin()"/>	
		</div>	
		<%@ include file="jsp/ca/caLogonHandle.jsp"%>
    <%}else{ %>		
     	<div class="dw-logon-form" style="top: 50%;right: 15%; margin-top: -220px;">
     		<div style="top: 8%;left:50%;margin-left:-50px;position: absolute; font-size: 15px;font-family: 微软雅黑;color: #555555; text-align: center;">
     			<div style="width: 100px;">系统登录</div>
     		</div>
     		
     		<%-- 读取txt获取医院编码--%>
     		<% 
     		if("".equals(current_yybm)||current_yybm == null){
     			StringBuffer strB = new StringBuffer();//strB用来存储jsp.txt文件里的内容
         		String path="c:\\config";  //目录分隔符必须用双斜杠
         		File file=new File(path,"pipconfig.txt");//
         		if(file.isFile() && file.exists()){ //判断文件是否存在

         			FileReader fr=new FileReader(file);   //字符输入流
             		BufferedReader br=new BufferedReader(fr);   //使文件可按行读取并具有缓冲功能
             	    
             		String str=br.readLine();
             		while(str!=null){
             		 strB.append(str);    //将读取的内容放入strB
             		 str=br.readLine();
             		}
             		br.close();            //关闭输入流
             		fr.close();		
             		
              		//base64解码
             		/* byte[] pdfBlob = SecUtil.base64Decode(strB.toString());
             		String strconfig = new String(pdfBlob); */

             		//获取yybm
            		String [] paratxt = strB.toString().split("<br>");
            		for (int i = 0 ; i < paratxt.length ;i++){
            			String paraone = paratxt[i];
            			int index = paraone.indexOf("::");
            			if(index >=0){
            				String key = paraone.substring(0,index);
            				String value = paraone.substring(index+2);
            				if("currentyybm".equals(key.toLowerCase())){
            					current_yybm = value;
            				}

            			}
            		}
         		}
   
     		}
     		%>
			
			<% if ("225".equals(GlobalPara.DBID)) {
				if("".equals(current_yybm) ||current_yybm == null ){ %>
					<input type="text" id="yybmInput" class="dw-logon-form-yybm" placeholder="请输入医院编码" onchange="getHospName()" />
				  <% }else{%>
				  <select name="yybm" id="yybmInput"  class="dw-logon-form-yybm"   >
				       <%  String [] yybmlist = current_yybm.split(","); 
				       String yybm = "",yymc = "";
				        for (int i = 0 ;i < yybmlist.length ; i ++) {
				             int index = yybmlist[i].indexOf(":");
				             if(index >= 0){
				            	 yybm = yybmlist[i].substring(0, index);
					             yymc = yybmlist[i].substring(index+1, yybmlist[i].length());  
				             } %>
				              <option value="<%= yybm%>" style="width:264px"><%=yymc %></option>
				      <%} %>
				  <%} %>
				</select>
			    <input type="text" id="yymcInput" class="dw-logon-form-yymc" placeHolder="医院名称" readonly="readonly"/>
			<%} else {
				if("".equals(current_yybm) ||current_yybm == null ){ %>
					<input type="text" id="yybmInput" class="dw-logon-form-yybm" placeholder="请输入医院编码" />
				<% }else{%>
				<select name="yybm" id="yybmInput"  class="dw-logon-form-yybm"   >
				     <%  String [] yybmlist = current_yybm.split(","); 
				     String yybm = "",yymc = "";
				     for (int i = 0 ;i < yybmlist.length ; i ++) {
				         int index = yybmlist[i].indexOf(":");
				         if(index >= 0){
				         yybm = yybmlist[i].substring(0, index);
					     yymc = yybmlist[i].substring(index+1, yybmlist[i].length());  
				      } %>
				      <option value="<%= yybm%>" style="width:264px"><%=yymc %></option>
				<%} %>
				<%} %>
				</select>
			<%} %>
			<input type="text" id="userNameInput" class="dw-logon-form-loginname" placeholder="请输入用户名"/>
			<input type="password" id="userPwdInput" class="dw-logon-form-pwd"  placeholder="请输入密码" autocomplete="off"/>
			<div style="<%=display %>">
			<img alt="点击刷新验证码" src="" id="validatecode" class="dw-logon-form-yzmimg"   />
			<input type="text" id="yzmInput" class="dw-logon-form-yzm" placeholder="请输入验证码"   />
			</div>
			
		    <!-- 	<input type="checkbox" id="logPassword" class="dw-logon-form-savepwd" value="1"/> -->
			<!-- <div class="logon_form_jzmm">记住密码</div> -->
			<div class="dw-logon-form-getloginname" onclick="retrieveUserName()"></div>
			<input type="button" id="logonBtn" class="dw-logon-form-btnlogin" onclick="onLogin()"/>
			<% if(GlobalNames.DEBUGMODE){ %>
			<input type="button" class="dw-logon-form-btndebug" onclick="debugLoginName();" style="display: none;"/>
            <% } %>				
			<div class="sVersion">
	          <p class="sysVersion">系统版本号:<%=current_version%></p>
	        </div>
			</div>
			<% if (use_encryptionCard.equals("true")) {%>		
				<OBJECT CLASSID="clsid:74B11C75-93E0-4760-B725-FF62641D0D6F" ID="PDFReader" 
	           width="0" height="0" type="application/x-qt-plugin"> </OBJECT>
			<% } %>	
						
		<%-- 登录逻辑 --%>
		



<%
	String requestURL = "webLogin.jsp?view=main&";

	String logonMode = GlobalNames.LOGON_MODE;
	String use_dukey =GlobalPara.USE_DUKEY.toLowerCase();
	String use_dauth =GlobalPara.USE_DAUTH.toLowerCase();

%>

<script type="text/javaScript">
	var logonMode = '<%=logonMode%>',
			$useridObj = $("#userNameInput"),
			$passwdObj = $("#userPwdInput"),
			$yybmObj = $("#yybmInput"),
			$yzbObj = $("#yzmInput"),
			$retrieveObj = $("#retrieveUserName"),
			ukeyReaderTimer = null,
			isSupplementChecking = false;

	$(document).ready(function(){
		initRetrieveUserName();

		$("#validatecode").click(function(){
			var i = Math.random();
			$(this).attr("src", "authcode?i=" + i);
		}).click();


		if(logonMode == "0") {
			logonInWithoutUKey();
		}else {
			logonInWithUKey();
		}
	});

	function retrieveUserName() {
		var __layer = $(".dw-getusername-bgmask");
		var __res=$(".dw-getusername-form");
		__layer.show();
		__res.show();
		$(".dw-getusername-form-content-card").focus();
	}

	function initRetrieveUserName() {
		$("<div class=\"dw-getusername-bgmask\"><iframe  scrolling='no' frameborder='0' class=\"dw-getusername-bgmask-frame\"></iframe></div>").appendTo("body");

		var sHTML= "<div class=\"dw-getusername-form\">"+
				"<div class=\"dw-getusername-form-content\">" +
				"<div class=\"dw-getusername-form-content-btnclose\"></div>"+
				"<div class=\"dw-getusername-form-content-placeholder\">请输入身份证号</div>" +
				"<input class=\"dw-getusername-form-content-card\" type=\"text\"/>" +
				"<div class=\"dw-getusername-form-content-loginname\"></div>" +
				"<div class=\"dw-getusername-form-content-btn\"></div>"+
				"</div>" +
				"</div>";
		$(sHTML).appendTo("body");

		var __layer = $(".dw-getusername-bgmask");
		var __res=$(".dw-getusername-form");
		var __pidObj = $(".dw-getusername-form-content-card");
		var __pid_hide_obj = $(".dw-getusername-form-content-placeholder");
		var __closeBtn = $(".dw-getusername-form-content-btnclose");
		var __loginName = $(".dw-getusername-form-content-loginname");

		// 绑定找回按钮
		$(".dw-getusername-form-content-btn").bind("click", function(){
			foundLoginName();
		});

		__res.bind("keydown", function(e){
			e.stopPropagation();
		});
		__closeBtn.bind("click", function(){
			closeRetrieveUserName();
		});

		__pidObj.bind("keydown", function(jEvent){
			__pid_hide_obj.hide();

			var keyCode = jEvent.which;

			if(keyCode == FrameConstants.KEYCODE_MAPPING.ENTER) {
				foundLoginName();
				jEvent.stopPropagation();
			}
		});

		__pidObj.bind("click", function(jEvent) {
			__pid_hide_obj.hide();
		});

		__pid_hide_obj.show();

		__res.find(".responseClose").bind("click", function(){
			setTimeout(function(){
				closeRetrieveUserName();
			},0);
		});

		function closeRetrieveUserName() {
			__pidObj.val("");
			__loginName.text("");
			__pid_hide_obj.show();

			__res.hide();
			__layer.hide();
		}

		function foundLoginName(){
			//个系统自己实现，根据输入的身份证好查询登录名
			var _pid_value = __pidObj.val(),
					url = null,
					loginName = null;

			if(!_pid_value){
				MsgBox.show("请先输入身份证号码，然后点击【申请找回】按钮!");
				return;
			}

			if(!IDCardUtil.checkSfzhm(_pid_value)) {
				MsgBox.show("你输入的身份证号码不合法，请重新输入！");
				return;
			}

			url = new URL("logon.do?method=foundLoginName");
			url.addPara("sfzhm", _pid_value);
			loginName = AjaxUtil.ajaxRequest(url.getURLString());

			if(AjaxUtil.checkException(loginName)) {
				__loginName.text(loginName);
				return ;
			}else {
				MsgBox.show("没有找到身份证号为【"+_pid_value+"】的人员的登录名");
			}
		}
	}

    function logonInWithoutUKey() {
        var loginName = CookieUtil.getCookie("loginName");
        var hospital = CookieUtil.getCookie("yybm");
        if (loginName) $useridObj.val(loginName);
        if (hospital && (!$yybmObj.is("select") || $yybmObj.find("option").filter(function () {
            return this.value === hospital;
        }).length)) $yybmObj.val(hospital);
        $passwdObj.focus();
    }

	function logonInWithUKey() {
		// 1.【用户名】录入框只读
		// 2.【密码】录入框获得焦点
		// 3.不允许勾选【记住密码】
		$useridObj.attr("readonly","readonly")
		$useridObj.css({
			"background" : "#BEBEBE"
		});
		$("#logPassword").prop("checked", false);
		$("#logPassword").prop("disabled", true);
		$("#logPassword").css("cursor", "not-allowed");
		$passwdObj.focus();

		//每隔固定时间读取ukey信息
		var zf = new ZF_KEY();
		ukeyReaderTimer = setInterval(function(){
			zf.read()["catch"](function(){
				return null;
			}).then(function(value){
				if(value) {
					if(value == $useridObj.val()) {
						return;
					}
					$useridObj.val(value);
					$passwdObj.val("");
					$passwdObj.focus();
				}else {
					MsgBox.show("登录请插入UKEY!");
					$useridObj.val("");
					$passwdObj.val("");
					$passwdObj.focus();
				}
			});
		}, 1000);
	}

	//获取医院名称
	function getHospName() {
		var $yymcObj = $("#yymcInput");
		var yybm = $yybmObj.val();

		var url = new URL("logon.do?method=getYymc");
		url.addPara("yybm", yybm);
		var loginYymcValue = AjaxUtil.ajaxRequest(url.getURLString());
		if (!AjaxUtil.checkException(loginYymcValue)) {
			MsgBox.show(loginYymcValue);
			return false;
		}

		if (window.webview && window.webview.editIniInfo) window.webview.editIniInfo("D:/pip/pipconfig.ini",'HOSPINFO','HospID', yybm);
		if (window.webview && window.webview.editIniInfo) window.webview.editIniInfo("D:/pip/pipconfig.ini",'HOSPINFO','HospName', loginYymcValue);
		$yymcObj.val(loginYymcValue);
		if ($useridObj.val() == "" || $useridObj.val() == null) {
			$useridObj.focus();
		} else {
			$passwdObj.focus();
		}
		return true;
	}

	//debug模式手动录入loginName
	function debugLoginName() {
		if(logonMode != "0" && $useridObj.attr("readonly") == "readonly") {
			$useridObj.removeAttr("readonly");
			$useridObj.css({
				"background" : "transparent"
			});
			$useridObj.focus();
		}
	}

	function onLogin() {
		if (isSupplementChecking) return;

		var yybmObj = document.getElementById("yybmInput");
		var yybm = yybmObj.value;

		// 医院编码为空时直接走登录
		if (!yybm || yybm === "") {
			doActualLogin();
			return;
		}

		isSupplementChecking = true;
		showLoginLoading();
		try {
			var url = new URL("logon.do?method=getLogonSupplementInfo");
			url.addPara("current_yybm", yybm);
			var result = AjaxUtil.ajaxRequest(url.getURLString());
			var data = JSON.parse(result);

			if (!data.hassupplement || data.hassupplement === "false") {
				resetLoginCheckState();
				doActualLogin();
				return;
			}

			hideLoginLoading();
			showLogonCountdownPopup(data.content, data.seconds, function() {
				isSupplementChecking = false;
				doActualLogin();
			});
		} catch(e) {
			resetLoginCheckState();
			doActualLogin();
		}
	}

	function resetLoginCheckState() {
		isSupplementChecking = false;
		hideLoginLoading();
	}

	function showLoginLoading() {
		try {
			if (typeof LoadingMaskLayer !== "undefined" && LoadingMaskLayer && LoadingMaskLayer.show) {
				LoadingMaskLayer.show();
			}
		} catch(e) {
			// 框架加载层不可用则忽略
		}
	}

	function hideLoginLoading() {
		try {
			if (typeof LoadingMaskLayer !== "undefined" && LoadingMaskLayer && LoadingMaskLayer.hide) {
				LoadingMaskLayer.hide();
			}
		} catch(e) {
			// 框架加载层不可用则忽略
		}
	}

	function doActualLogin() {
		var useridObj = document.getElementById("userNameInput");
		var passwdObj = document.getElementById("userPwdInput");
		var yybmObj = document.getElementById("yybmInput");
		var yzbObj = document.getElementById("yzmInput");
		var mm = passwdObj.value;
        var encodedPassword = mm;

		var SM4_MODE = "<%=GlobalPara.SM4_MODE%>";
		if (SM4_MODE == "ECB") {
			var SM4 = new SM4Util();
			SM4.secretKey="<%=GlobalPara.SM4_SECRET_KEY%>";
			encodedPassword = SM4.encryptData_ECB(mm);
		} else if (SM4_MODE == "CBC") {
			var SM4 = new SM4Util();
			SM4.secretKey="<%=GlobalPara.SM4_SECRET_KEY%>";
			SM4.iv = "<%=GlobalPara.SM4_IV%>";
			encodedPassword = SM4.encryptData_CBC(mm);
		} else {//双重md5加密
			encodedPassword = md5(md5(mm));
		}

		var passWordLogSign = $("#logPassword").prop("checked") ? "1" : "0";
		login(useridObj.value, encodedPassword, passWordLogSign,yybmObj.value,mm,yzbObj.value);
	}

	function showLogonCountdownPopup(content, seconds, callback) {
		seconds = parseInt(seconds, 10);
		if (isNaN(seconds) || seconds < 0) {
			seconds = 10;
		}

		var bgmask = document.createElement("div");
		bgmask.id = "supplementBgMask";
		bgmask.className = "supplement-bgmask";

		var popup = document.createElement("div");
		popup.id = "supplementPopup";
		popup.className = "supplement-popup";
		popup.innerHTML = '<div class="supplement-popup-title">' +
				'<span>登录提示</span>' +
				'</div>' +
				'<div class="supplement-popup-content">' +
				'<span id="supplementContent"></span>' +
				'</div>' +
				'<div class="supplement-popup-footer">' +
				'<span id="supplementTimer" class="supplement-timer"></span>' +
				'</div>';

		document.body.appendChild(bgmask);
		document.body.appendChild(popup);
		document.getElementById("supplementContent").textContent = content;

		var remaining = seconds;
		var timerEl = document.getElementById("supplementTimer");
		timerEl.innerHTML = "提示剩余存在时间：" + remaining + "s";

		var timer = setInterval(function() {
			remaining--;
			if (remaining <= 0) {
				clearInterval(timer);
				if (bgmask.parentNode) {
					document.body.removeChild(bgmask);
				}
				if (popup.parentNode) {
					document.body.removeChild(popup);
				}
				if (typeof callback === "function") {
					try {
						callback();
					} catch(e) {
						// 回调异常不影响弹窗清理
					}
				}
			} else {
				timerEl.innerHTML = "提示剩余存在时间：" + remaining + "s";
			}
		}, 1000);
	}

	/**
	 * 登录方法
	 */
	function login(loginName, password, passWordLogSign,yybm,mm,yzm) {
		try{
			if ("225" == <%=GlobalPara.DBID%>) {
				if (window.webview && window.webview.editIniInfo) window.webview.editIniInfo("D:/pip/pipconfig.ini",'OPERATOR','UserID', loginName);
			}
			var use_dukey = "<%=use_dukey%>";
			if(use_dukey == "true"){
				var dukeyid = checkdukey();
				if(dukeyid == null){
					return false;
				}
				var result = checkdukeyuser(dukeyid,loginName,yybm);
				if(result == false){
					return false;
				}
				var changeflag = result.changeflag;
				var bindczy = result.bindczy;

				if(bindczy == null || bindczy == ""){
					if(confirm("当前Ukey【"+dukeyid+"】尚未绑定任何操作人员,是否需要自动绑定该操作人员【"+loginName+"】！")){
						var urlbin = new URL("logon.do?method=bindDukey");
						urlbin.addPara("ryid", loginName);
						urlbin.addPara("dukeyid", dukeyid);
						var result = AjaxUtil.ajaxRequest(urlbin.getURLString());
						if (!AjaxUtil.checkException(result)) {
							MsgBox.show(result);
							return false;
						}
					}
				}else if(changeflag){//自动重新绑定ukey
					var urlbin = new URL("logon.do?method=bindDukey");
					urlbin.addPara("ryid", loginName);
					urlbin.addPara("dukeyid", dukeyid);
					var result = AjaxUtil.ajaxRequest(urlbin.getURLString());
					if (!AjaxUtil.checkException(result)) {
						MsgBox.show(result);
						return false;
					}
				}
			}

			//验证数字授权书DDA
			var use_dauth = "<%=use_dauth%>";
			if(use_dauth == "true"){
				var urldda = new URL("logon.do?method=checkDDAInfo");
				urldda.addPara("userid", loginName);
				urldda.addPara("current_yybm", yybm);
				var ddainfo = AjaxUtil.ajaxRequest(urldda.getURLString());

				try{
					var result  = JSON.parse(ddainfo);
				}catch(oE) {
					MsgBox.show(ddainfo);
					return;
				}

				var days = result.days;
				var zzrq = result.zzrq;
				if(days <32 && days >0){
					alert("您的数字授权书将在"+days+"天后("+zzrq+")到期，请联系地纬公司申请下年度的数字授权书！");
				}else if(days == 0){
					alert("您的数字授权书将在明天("+zzrq+")到期，请联系地纬公司申请下年度的数字授权书！");
				}else if(days< 0){
					alert("您的数字授权书已到期，请联系地纬公司申请下年度的数字授权书！");
				};
			}

			var url = new URL("logon.do?method=doLogon");
			url.addPara("userid", loginName);
			url.addPara("passwd", password);
			url.addPara("passWordLogSign", passWordLogSign);
			url.addPara("current_yybm", yybm);
			url.addPara("yzm", yzm);
			if ("1" == <%=GlobalPara.BLOCK_WEAK_PWD%>) {//取明码校验密码强度
				url.addPara("mm", mm);
			}

			var msg = AjaxUtil.ajaxRequest(url.getURLString());
			if(!AjaxUtil.checkException(msg)){
				AjaxUtil.showException(msg);
				return;
			}
			try{
				var result  = JSON.parse(msg);
			}catch(oE) {
				MsgBox.show(msg);
				CookieUtil.delCookie("password");
				$passwdObj.val("");
				$useridObj.val(loginName);
				$passwdObj.focus();
				$("#yzmInput").val("");
				$("#validatecode").click();
				return;
			}

			GlobalNames.__usersession_uuid = result.__usersession_uuid;
			clearInterval(ukeyReaderTimer);

			var mainUrl = '<%=requestURL%>' + new Date().getMilliseconds() + "&__usersession_uuid=" + GlobalNames.__usersession_uuid;
			if (!result.__usersession_uuid) {
                MsgBox.show("登录响应未包含会话标识，请检查返回结果。");
                return;
            }
            window.location.replace(mainUrl);

			if ("225" == <%=GlobalPara.DBID%>) {
				if (window.webview && window.webview.getPCNetWorkInfo) collectLoginMsg();
			}

		}catch(oE){
			alert(oE.message);
		};
	}

	document.onkeydown = function(){
		if (13 == getEvent().keyCode) {
			onLogin();
		}
	};
	function checkdukey(){
		var dukeyid = dUKeyUtil.checkCurrentDUKey();
		if(dukeyid==null)
			return null;
		var challengeNumber = dUKeyUtil.getChallengeNumber(dukeyid);
		if(challengeNumber === null){
			return null;
		}
		var battleNumber = dUKeyUtil.getBattleNumber(dukeyid,challengeNumber);
		if(battleNumber === null){
			return null;
		}
		var rv = dUKeyUtil.assertDUKeyValid(dukeyid,battleNumber);
		if(rv==null)
			return;
		if(rv == "f"){
			throw new Error("DUKEY认证失败！");
		}
		return dukeyid;
	}


	function checkdukeyuser(dukeyid,loginName,yybm){
		var dukeyinfo = dUKeyUtil.getDUKeyInfo(dukeyid);
		if(dukeyinfo==null)
			return;

		var holderid = dukeyinfo.holderid;
		var dukeyid = dukeyinfo.dukeyid;
		var urlcheck= new URL("logon.do?method=checkUkeyUser");
		urlcheck.addPara("holderid", holderid);
		urlcheck.addPara("dukeyid", dukeyid);
		urlcheck.addPara("userid", loginName);
		urlcheck.addPara("current_yybm", yybm);

		var result ;
		var checkresult = AjaxUtil.ajaxRequest(urlcheck.getURLString());
		try{
			result = JSON.parse(checkresult);
		}catch(oE) {
			MsgBox.show(checkresult);
			return false;
		}
		return result;

	}

	// 读取加密卡中的数据
	function getEncryptionCardInfo(){
		var resultBstr = PDFReader.DOpenCardV21();
		var resu = PDFReader.DEncryptMessageV21(resultBstr);
		var num =PDFReader.DDecryptMessageV21(resu);
		var yybm = num.substr(3 ,6);
		return yybm;
	};

	//收集登陆信息
	function collectLoginMsg(){
		var info = window.webview.getPCNetWorkInfo();
		var ip = info.ip;
		var mac = info.mac;
		var hostname = info.hostname;
		var url= new URL("logon.do?method=collectLoginMsg");
		url.addPara("ip",ip);
		url.addPara("mac",mac);
		url.addPara("hostname",hostname);
		var result = AjaxUtil.ajaxRequest(url.getURLString());
		if (!AjaxUtil.checkException(result)) {
			return true;
		}
		return true;
	}
</script>

	<%} %>			
	
<script>
(function () {
    var submitted = false;
    var paused = false;
    var lastActivity = Date.now();
    var idleMilliseconds = 5000;
    var timer = null;
    var events = ['mousemove', 'mousedown', 'keydown', 'input', 'change', 'touchstart', 'touchmove', 'wheel', 'scroll'];
    var status;
    function markActivity() { lastActivity = Date.now(); }
    function cleanup() {
        if (timer !== null) { clearInterval(timer); timer = null; }
        for (var i = 0; i < events.length; i++) {
            document.removeEventListener(events[i], markActivity, true);
        }
        document.removeEventListener('visibilitychange', markActivity, true);
    }
    function manualSubmit() {
        submitted = true;
        cleanup();
        if (status) status.textContent = '已交给原登录流程处理；失败后可手动重试。';
    }
    $(document).ready(function () {
        // Defaults requested for this dedicated entry. No password cookie/storage.
        document.getElementById('userNameInput').value = '账号';
        document.getElementById('userPwdInput').value = '密码';
        var box = document.createElement('div');
        box.style.cssText = 'position:fixed;left:20px;bottom:20px;padding:12px 16px;background:white;border:1px solid #ddd;border-radius:6px;z-index:10000;font:14px sans-serif';
        box.innerHTML = '<span id="webIdleStatus"></span> <button id="webIdlePause" type="button" style="margin-left:12px">暂停自动登录</button>';
        document.body.appendChild(box);
        status = document.getElementById('webIdleStatus');
        document.getElementById('webIdlePause').addEventListener('click', function () {
            paused = !paused;
            lastActivity = Date.now();
            this.textContent = paused ? '恢复自动登录' : '暂停自动登录';
            status.textContent = paused ? '自动登录已暂停' : '连续5秒无操作后自动登录';
        });
        document.getElementById('userNameInput').setAttribute('autocomplete', 'username');
        document.getElementById('userPwdInput').setAttribute('autocomplete', 'current-password');
        document.getElementById('logonBtn').addEventListener('click', manualSubmit);
        document.addEventListener('keydown', function (e) { if (e.keyCode === 13) manualSubmit(); }, true);
        for (var i = 0; i < events.length; i++) {
            document.addEventListener(events[i], markActivity, true);
        }
        document.addEventListener('visibilitychange', markActivity, true);
        lastActivity = Date.now();
        status.textContent = '连续5秒无操作后自动登录';
        timer = setInterval(function () {
            if (submitted || paused) return;
            if (document.hidden) { lastActivity = Date.now(); return; }
            var user = document.getElementById('userNameInput');
            var pass = document.getElementById('userPwdInput');
            var hosp = document.getElementById('yybmInput');
            var code = document.getElementById('yzmInput');
            var codeRequired = '<%=sfkqdlyzm%>' === '1';
            if (!user.value || !pass.value || !hosp.value) {
                lastActivity = Date.now();
                status.textContent = '请补全医院编码、账号和密码';
                return;
            }
            if (codeRequired && !code.value) {
                lastActivity = Date.now();
                status.textContent = '请先填写验证码，填写后5秒无操作自动登录';
                return;
            }
            var remaining = idleMilliseconds - (Date.now() - lastActivity);
            if (remaining > 0) {
                status.textContent = '无操作 ' + Math.ceil(remaining / 1000) + ' 秒后自动登录';
                return;
            }
            submitted = true;
            cleanup();
            status.textContent = '正在登录；失败后请手动重试';
            onLogin();
        }, 200);
    });
})();
</script>

</body>
</html>
<style>
	.mhs5-logon-title {
		position: absolute;
		right: 300px;
		top: 20px;
		font-size: 24px;
		border: none;
		width: 280px;
		height: 17px;
		background: transparent;
		color: white;
	}
	.sVersion {
		width: 1200px;
		height: 150px;
		margin-left: -1000px;
		margin-top: 150%;
		font-weight:bold
	}
	/* 验证码录入框 */
	.dw-logon-form-yzm {
		position: absolute;
		left: 155px;
		top: 194px;
		border: none;
		width: 100px;
		height: 29px;
		font: 400 16px/2 "微软雅黑";
		background:#fff
	}
	/* 验证码图片 */
	.dw-logon-form-yzmimg {
		position: absolute;
		left: 55px;
		top: 194px;
		width: 80px;
		height: 22px;
		cursor: pointer;
	}
	/* 登录补充信息弹窗遮罩 */
	.supplement-bgmask {
		position: fixed;
		top: 0;
		left: 0;
		width: 100%;
		height: 100%;
		background: rgba(0, 0, 0, 0.5);
		z-index: 9998;
	}
	/* 登录补充信息弹窗 */
	.supplement-popup {
		position: fixed;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%);
		width: 500px;
		max-height: 400px;
		background: #fff;
		border-radius: 6px;
		box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
		z-index: 9999;
		display: flex;
		flex-direction: column;
	}
	.supplement-popup-title {
		padding: 15px 20px;
		font-size: 18px;
		font-weight: bold;
		color: #333;
		border-bottom: 1px solid #e5e5e5;
		text-align: center;
	}
	.supplement-popup-content {
		flex: 1;
		padding: 30px 25px;
		overflow-y: auto;
		max-height: 250px;
		font-size: 15px;
		line-height: 1.8;
		color: #e74c3c;
		font-family: "微软雅黑", SimHei, sans-serif;
		text-align: center;
	}
	.supplement-popup-footer {
		padding: 15px 20px;
		border-top: 1px solid #e5e5e5;
		text-align: center;
	}
	.supplement-timer {
		font-size: 20px;
		color: #f39c12;
		font-weight: bold;
	}
</style>


<% } %>
