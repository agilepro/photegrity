<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" session="true"%>
<%@page errorPage="error.jsp" %>
<%@page import="java.util.List"%>
<%@page import="java.io.File"%>
<%@page import="java.io.FileReader"%>
<%@page import="java.io.BufferedReader"%>
<%@page import="java.util.Properties"%>
<%@page import="bogus.UtilityMethods"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%>
<%
    request.setCharacterEncoding("UTF-8");
    /**********************************************
    * Please Read Before Working on this Page
    *
    * The "PasswordPanel" replaces a page requested with a password prompt.
    * User asks for a particular page, it is not there, so this gets displayed.
    * clicking login goes back to the same web address, but this time, since
    * you are logged in, it works.
    *
    * The nice thing about this paradigm is that the address seen int he
    * browser remain the same, and users can put in their favories without problem
    *
    * USAGE: At the top of every page, before any output is produced, y
    * you must have the  following:
    *
    * 1 request.setCharacterEncoding("UTF-8");
    * 2 WFSession wfSession = (WFSession)session.getAttribute("ModelsessionID");
    * 3 if (wfSession == null) {
    * 4     %)(jsp:include page="PasswordPanel.jsp" flush="true"/)(%
    * 5     return;
    * 6 }
    *
    * line 1 is always needed
    * line 2 attempts to see if there is a current session
    * line 4 includes the PasswordPanel, put angle brackets in for the parens
    * line 5 return is needed to avoid getting anything else in the page.
    *
    ************************************************/

    StringBuffer s1 = request.getRequestURL();
    if (request.getQueryString() != null) {
        s1.append("?");
        s1.append(request.getQueryString());
    }
    String goPage = s1.toString();

    // make sure that we are not getting hacked from a single address
    String requestIPAddr = request.getRemoteAddr();
    //LoginAttemptRecord.checkLoginThreshold(requestIPAddr);

    String failureCountWarning = null;
    //if (LoginAttemptRecord.triesLeft(requestIPAddr) < 4) {
    //    failureCountWarning = "Warning: only "+
    //            (LoginAttemptRecord.triesLeft(requestIPAddr))+
    //            " login attempts left.";
    //}
%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>Login Page</title>
<style>#gb{font:13px/27px Arial,sans-serif;height:30px}#gbz,#gbg{position:absolute;white-space:nowrap;top:0;height:30px;z-index:1000}#gbz{left:0;padding-left:4px}#gbg{right:0;padding-right:5px}#gbs{background:transparent;position:absolute;top:-999px;visibility:hidden;z-index:998}.gbto #gbs{background #fff}#gbx3,#gbx4{background-color:#2d2d2d;background-image:none;_background-image:none;background-position:0 -138px;background-repeat:repeat-x;border-bottom:1px solid #000;font-size:24px;height:29px;_height:30px;opacity:1;filter:alpha(opacity=100);position:absolute;top:0;width:100%;z-index:990}#gbx3{left:0}#gbx4{right:0}#gbb{position:relative}#gbbw{right:0;left:0;position:absolute;top:30px;width:100%}.gbtcb{position:absolute;visibility:hidden}#gbz .gbtcb{right:0}#gbg .gbtcb{left:0}.gbxx{display:none !important}.gbm{position:absolute;z-index:999;top:-999px;visibility:hidden;text-align:left;border:1px solid #bebebe;background:#fff;-moz-box-shadow:-1px 1px 1px rgba(0,0,0,.2);-webkit-box-shadow:0 2px 4px rgba(0,0,0,.2);box-shadow:0 2px 4px rgba(0,0,0,.2)}.gbrtl .gbm{-moz-box-shadow:1px 1px 1px rgba(0,0,0,.2)}.gbto .gbm,.gbto #gbs{top:29px;visibility:visible}#gbz .gbm,#gbz #gbs{left:0}#gbg .gbm,#gbg #gbs{right:0}.gbxms{background-color:#ccc;display:block;position:absolute;z-index:1;top:-1px;left:-2px;right:-2px;bottom:-2px;opacity:.4;-moz-border-radius:3px;filter:progid:DXImageTransform.Microsoft.Blur(pixelradius=5);*opacity:1;*top:-2px;*left:-5px;*right:5px;*bottom:4px;-ms-filter:"progid:DXImageTransform.Microsoft.Blur(pixelradius=5)";opacity:1\0/;top:-4px\0/;left:-6px\0/;right:5px\0/;bottom:4px\0/}.gbma{position:relative;top:-1px;border-style:solid dashed dashed;border-color:transparent;border-top-color:#c0c0c0;display:-moz-inline-box;display:inline-block;font-size:0;height:0;line-height:0;width:0;border-width:3px 3px 0;padding-top:1px;left:4px}#gbztms1,#gbi4m1,#gbi4s,#gbi4t{zoom:1}.gbtc,.gbmc,.gbmcc{display:block;list-style:none;margin:0;padding:0}.gbmc{background:#fff;padding:10px 0;position:relative;z-index:2;zoom:1}.gbt{position:relative;display:-moz-inline-box;display:inline-block;line-height:27px;padding:0;vertical-align:top}.gbt{*display:inline}.gbto{box-shadow:0 2px 4px rgba(0,0,0,.2);-moz-box-shadow:0 2px 4px rgba(0,0,0,.2);-webkit-box-shadow:0 2px 4px rgba(0,0,0,.2)}.gbzt,.gbgt{cursor:pointer;display:block;text-decoration:none !important}.gbts{border-left:1px solid transparent;border-right:1px solid transparent;display:block;*display:inline-block;padding:0 5px;position:relative;z-index:1000}.gbts{*display:inline}.gbto .gbts{background:#fff;border-color:#bebebe;color:#36c;padding-bottom:1px;padding-top:2px}.gbz0l .gbts{color:#fff;font-weight:bold}.gbtsa{padding-right:9px}#gbz .gbzt,#gbz .gbgt,#gbg .gbgt{color:#ccc!important}.gbtb2{display:block;border-top:2px solid transparent}.gbto .gbzt .gbtb2,.gbto .gbgt .gbtb2{border-top-width:0}.gbtb .gbts{background:url(//ssl.gstatic.com/gb/images/h_bedf916a.png);_background:url(//ssl.gstatic.com/gb/images/h8_3dd87cd8.png);background-position:-27px -22px;border:0;font-size:0;padding:29px 0 0;*padding:27px 0 0;width:1px}.gbzt-hvr,.gbzt:focus,.gbgt-hvr,.gbgt:focus{background-color:#4c4c4c;background-image:none;_background-image:none;background-position:0 -102px;background-repeat:repeat-x;outline:none;text-decoration:none !important}.gbpdjs .gbto .gbm{min-width:99%}.gbz0l .gbtb2{border-top-color:#dd4b39!important}#gbi4s,#gbi4s1{font-weight:bold}#gbg6.gbgt-hvr,#gbg6.gbgt:focus{background-color:transparent;background-image:none}.gbg4a{font-size:0;line-height:0}.gbg4a .gbts{padding:27px 5px 0;*padding:25px 5px 0}.gbto .gbg4a .gbts{padding:29px 5px 1px;*padding:27px 5px 1px}#gbi4i,#gbi4id{left:5px;border:0;height:24px;position:absolute;top:1px;width:24px}.gbto #gbi4i,.gbto #gbi4id{top:3px}.gbi4p{display:block;width:24px}#gbi4id,#gbmpid{background:url(//ssl.gstatic.com/gb/images/h_bedf916a.png);_background:url(//ssl.gstatic.com/gb/images/h8_3dd87cd8.png)}#gbi4id{background-position:-29px -54px}#gbmpid{background-position:-58px 0px}#gbmpi,#gbmpid{border:none;display:inline-block;margin-top:10px;height:48px;width:48px}.gbmpiw{display:inline-block;line-height:9px;margin-left:20px}#gbmpi,#gbmpid,.gbmpiw{*display:inline}#gbg5{font-size:0}#gbgs5{padding:5px !important}.gbto #gbgs5{padding:7px 5px 6px !important}#gbi5{background:url(//ssl.gstatic.com/gb/images/h_bedf916a.png);_background:url(//ssl.gstatic.com/gb/images/h8_3dd87cd8.png);background-position:0 0;display:block;font-size:0;height:17px;width:16px}.gbto #gbi5{background-position:-6px -22px}.gbn .gbmt,.gbn .gbmt:visited,.gbnd .gbmt,.gbnd .gbmt:visited{color:#dd8e27 !important}.gbf .gbmt,.gbf .gbmt:visited{color:#900 !important}.gbmt,.gbml1,.gbmt:visited,.gbml1:visited{color:#36c !important;text-decoration:none !important}.gbmt,.gbmt:visited{display:block}.gbml1,.gbml1:visited{display:inline-block;margin:0 10px;padding:0 10px}.gbml1{*display:inline}.gbml1-hvr,.gbml1:focus{background:#eff3fb;outline:none}#gbpm .gbml1{display:inline;margin:0;padding:0;white-space:nowrap}#gbpm .gbml1-hvr,#gbpm .gbml1:focus{background:none;text-decoration:underline !important}.gbmt{padding:0 20px}.gbmt-hvr,.gbmt:focus{background:#eff3fb;cursor:pointer;outline:0 solid black;text-decoration:none !important}.gbm0l,.gbm0l:visited{color:#000 !important;font-weight:bold}.gbmh{border-top:1px solid #e5e5e5;font-size:0;margin:10px 0}#gbd4 .gbmh{margin:0}.gbmtc{padding:0;margin:0;line-height:27px}.GBMCC:last-child:after,#GBMPAL:last-child:after{content:'\0A\0A';white-space:pre;position:absolute}#gbd4 .gbpc,#gbmpas .gbmt{line-height:17px}#gbd4 .gbpgs .gbmtc{line-height:27px}#gbmpas .gbmt{padding-bottom:10px;padding-top:10px}#gbmple .gbmt,#gbmpas .gbmt{font-size:15px}#gbd4 .gbpc{display:inline-block;margin:6px 0 10px;margin-right:50px;vertical-align:top}#gbd4 .gbpc{*display:inline}.gbpc .gbps,.gbpc .gbps2{display:block;margin:0 20px}#gbmplp.gbps{margin:0 10px}.gbpc .gbps{color:#000;font-weight:bold}.gbpc .gbps2{font-size:13px}.gbpc .gbpd{margin-bottom:5px}.gbpd .gbmt,.gbmpmtd .gbmt{color:#666 !important}.gbmpme,.gbps2{color:#666;display:block;font-size:11px}.gbp0 .gbps2,.gbmpmta .gbmpme{font-weight:bold}#gbmpp{display:none}#gbd4 .gbmcc{margin-top:5px}.gbpmc{background:#edfeea}.gbpmc .gbmt{padding:10px 20px}#gbpm{*border-collapse:collapse;border-spacing:0;margin:0;white-space:normal}#gbpm .gbmt{border-top:none;color:#666 !important;font:11px Arial,sans-serif}#gbpms{*white-space:nowrap}.gbpms2{font-weight:bold;white-space:nowrap}#gbmpal{*border-collapse:collapse;border-spacing:0;margin:0;white-space:nowrap}.gbmpala,.gbmpalb{font:13px Arial,sans-serif;line-height:27px;padding:10px 20px 0;white-space:nowrap}.gbmpala{padding-left:0;text-align:left}.gbmpalb{padding-right:0;text-align:right}.gbp0 .gbps,.gbmpmta .gbmpmn{color:#000;display:inline-block;font-weight:bold;padding-right:34px;position:relative}.gbp0 .gbps,.gbmpmta .gbmpmn{*display:inline}.gbmpmtc,.gbp0i{background:url(//ssl.gstatic.com/gb/images/h_bedf916a.png);_background:url(//ssl.gstatic.com/gb/images/h8_3dd87cd8.png);background-position:0 -54px;position:absolute;height:21px;width:24px;right:0;top:-3px}.gbsup{color:#dd4b39;font:bold 9px/17px Verdana,Arial,sans-serif;margin-left:4px;vertical-align:top}#gbd1 .gbmc,#gbd3 .gbmc{padding:0}#gbgs1{padding-top:0;text-align:center}.gbto #gbi1{padding-top:2px}#gbi1{color:#fff;display:block;font-size:11px;font-weight:bold;position:relative;width:21px}#gbi1c{bottom:-4px;color:#fff;display:block;font-size:11px;font-weight:bold;position:absolute;width:21px;-moz-transition-property:bottom;-moz-transition-duration:0;-o-transition-property:bottom;-o-transition-duration:0;-webkit-transition-property:bottom;-webkit-transition-duration:0}#gbi1a{background:url(//ssl.gstatic.com/gb/images/h_bedf916a.png);_background:url(//ssl.gstatic.com/gb/images/h8_3dd87cd8.png);background-position:0 -274px;overflow:hidden;position:absolute;right:5px;top:3px;height:20px;width:21px}.gbto #gbi1a{_background-position:-52px -274px}#gbi1a.gbid{background-position:-26px -274px}.gbto #gbi1a.gbid{_background-position:-78px -274px}#gbi1.gbids{color:#999}.gbto #gbi1a{top:5px}#gbg3 .gbts{line-height:20px}.gbgsc{padding-bottom:7px;position:relative;top:3px}.gbgsca,.gbgscb{background:url(//ssl.gstatic.com/gb/images/h_bedf916a.png) no-repeat;_background:url(//ssl.gstatic.com/gb/images/h8_3dd87cd8.png) no-repeat;height:20px;position:absolute;top:0;width:3px}.gbgsca{left:0;background-position:0 -300px}.gbgscb{right:0;background-position:-153px -300px}.gbgsb{background:url(//ssl.gstatic.com/gb/images/h_bedf916a.png);_background:url(//ssl.gstatic.com/gb/images/h8_3dd87cd8.png);background-position:-3px -300px;height:20px;right:3px;left:3px;position:absolute;top:0}.gbgss{padding:0 6px;visibility:hidden}.gbgst,.gbgsta{color:#666;padding-right:5px;padding-left:3px}.gbgsta{display:none}.gbto .gbgsb,.gbto .gbgsca,.gbto .gbgscb{background:none}.gbto .gbgst{display:none}.gbgsc,.gbgst,.gbto .gbgsta{display:inline-block}.gbgsc,.gbgst,.gbto .gbgsta{*display:inline}#gbns{display:none}.gbmwc,#gbwc{right:0;position:absolute;top:-999px;width:440px;z-index:1000}#gbwc.gbmwca{top:0}#gbmpi,#gbmpid{margin-right:0;height:96px;width:96px}.gbmsg{display:none;position:absolute;top:0}.gbmsgo .gbmsg{display:block;background:#fff;width:100%;text-align:center;z-index:3;top:30%}#gbd1,#gbd1 .gbmc{width:440px;height:190px}#gbd3,#gbd3 .gbmc{width:440px;height:8em}
</style>
<style id="gstyle">body{margin:0;overflow-y:scroll}#gog{padding:3px 8px 0}.gac_m td{line-height:17px}body,td,a,p,.h{font-family:arial,sans-serif}.h{color:#12c;font-size:20px}.q{color:#00c}.ts td{padding:0}.ts{border-collapse:collapse}em{font-weight:bold;font-style:normal}.lst{height:20px;width:496px}.ds{display:-moz-inline-box;display:inline-block}span.ds{margin:3px 0 4px;margin-left:4px}.ctr-p{margin:0 auto;min-width:833px}.jhp input[type="submit"]{background-image:-moz-linear-gradient(top,#f5f5f5,#f1f1f1);-moz-border-radius:2px;-moz-user-select:none;background-color:#f5f5f5;background-image:linear-gradient(top,#f5f5f5,#f1f1f1);background-image:-o-linear-gradient(top,#f5f5f5,#f1f1f1);border:1px solid #dcdcdc;border:1px solid rgba(0, 0, 0, 0.1);border-radius:2px;color:#666;cursor:default;font-family:arial,sans-serif;font-size:11px;font-weight:bold;height:29px;line-height:27px;margin:11px 6px;min-width:54px;padding:0 8px;text-align:center}.jhp input[type="submit"]:hover{background-image:-moz-linear-gradient(top,#f8f8f8,#f1f1f1);-moz-box-shadow:0 1px 1px rgba(0,0,0,0.1);background-color:#f8f8f8;background-image:linear-gradient(top,#f8f8f8,#f1f1f1);background-image:-o-linear-gradient(top,#f8f8f8,#f1f1f1);border:1px solid #c6c6c6;box-shadow:0 1px 1px rgba(0,0,0,0.1);color:#333}.jhp input[type="submit"]:focus{border:1px solid #4d90fe;outline:none}input{font-family:inherit}a.gb1,a.gb2,a.gb3,a.gb4{color:#11c !important}body{background:#fff;color:#222}input{-moz-box-sizing:content-box}a{color:#12c;text-decoration:none}a:hover,a:active{text-decoration:underline}.fl a{color:#12c}a:visited{color:#61c}a.gb1,a.gb4{text-decoration:underline}a.gb3:hover{text-decoration:none}#ghead a.gb2:hover{color:#fff!important}.sblc{padding-top:5px}.sblc a{display:block;margin:2px 0;margin-left:13px;font-size:11px;}.lsbb{height:30px;display:block}.pp-new-desktop,.pp-new-mobile{color:red}.ftl,#footer a{color:#666;margin:2px 10px 0}#footer a:active{color:#dd4b39}.lsb{border:none;color:#000;cursor:pointer;height:30px;margin:0;outline:0;font:15px arial,sans-serif;vertical-align:top}.lst:focus{outline:none}#addlang a{padding:0 3px}.gac_v div{display:none}.gac_v .gac_v2,.gac_bt{display:block!important}body,html{font-size:small}h1,ol,ul,li{margin:0;padding:0}.nojsb{display:none}.nojsv{visibility:hidden}#body,#footer{display:block}#footer{font-size:10pt;min-height:49px;position:relative}#footer>div{border-top:1px solid #ebebeb;bottom:0;padding-top:3px;position:absolute;width:100%}#flci{float:left;margin-left:-260px;text-align:left;width:260px}#fll{float:right;text-align:right;width:100%}#ftby{padding-left:260px}#ftby>div,#fll>div,#footer a{display:inline-block}@media only screen and (min-width:1222px){#ftby{margin: 0 44px}}.nbcl{background:url(/images/nav_logo104.png) no-repeat -140px -230px;height:11px;width:11px}
</style>
<style>#ss-box{background:#fff;border:1px solid;border-color:#c9d7f1 #36c #36c #a2bae7;left:0;margin-top:.1em;position:absolute;visibility:hidden;z-index:101}#ss-box a{display:block;padding:.2em .31em;text-decoration:none}#ss-box a:hover{background:#4D90FE;color:#fff!important}a.ss-selected{color:#222!important;font-weight:bold}a.ss-unselected{color:#12c!important}.ss-selected .mark{display:inline}.ss-unselected .mark{visibility:hidden}#ss-barframe{background:#fff;left:0;position:absolute;visibility:hidden;z-index:100}#logo span,.lsb{background:url(/images/nav_logo104.png) no-repeat;overflow:hidden}#logo{display:block;height:41px;margin:0;overflow:hidden;position:relative;width:114px}#logo img{background:#f5f5f5;border:0;left:-0px;position:absolute;top:-41px}#logo span{cursor:pointer}#logocont{z-index:1;padding-left:16px;padding-right:10px;margin-top:-2px;}.big #logocont{padding-left:44px;padding-right:12px}#gac_scont .gac_od{z-index:101}#gac_scont .gac_id{border:1px solid #ccc;border-top-color:#d9d9d9;box-shadow:0 2px 4px rgba(0,0,0,0.2);-mox-box-shadow:0 2px 4px rgba(0,0,0,0.2);-webkit-box-shadow:0 2px 4px rgba(0,0,0,0.2);}#gac_scont .gac_b,#gac_scont .gac_b td.gac_c,#gac_scont .gac_b td.gac_d{background:#eee}.sfccl{font-size:11px;margin-right:0;position:relative;z-index:100}.sfccl .gl{display:block;margin-right:260px}.sfccl a.gl,.sfccl a.gl:visited{color:#36c}#sftab:hover .lst-tbb{border-color:#a0a0a0 #b9b9b9 #b9b9b9 #b9b9b9!important;}.lst-d{background-color:#fff;border:1px solid #d9d9d9;border-top-color:#c0c0c0;height:27px;}.lst-d:hover{-moz-box-shadow:inset 0px 1px 2px rgba(0,0,0,0.3);box-shadow:inset 0px 1px 2px rgba(0,0,0,0.3);}.lst-d-f .lst-tbb,.lst-d-f.lst-tbb,#sftab.lst-d-f:hover .lst-tbb{border-color:#4d90fe!important;}#bsb{display:block;margin-top:78px}.lst{width:90%;border:0;padding-left:6px;padding-right:10px;float:left;padding-top:0px!important;margin-top:4px;margin-bottom:0px;}.lst:focus{outline:none}.lst-t{width:100%;height:26px;padding:0;background:#fff}.lst-td{border:solid #999;border-width:0 0 1px 1px}#lst-ib{color:#000;}.gsib_a>div{height:22px!important}.gsfi,.lst{line-height:1.2em!important;height:1.2em!important;font:17px arial,sans-serif}.gsfs{font:17px arial,sans-serif}button[name="btnG"],.tsf-p .lsb:active{background:transparent;color:transparent;font-size:0;overflow:hidden;position:relative;width:100%}.sbico{background:url(/images/nav_logo104.png) no-repeat -137px -243px;color:transparent;display:inline-block;height:15px;margin:0 auto;margin-top:-1px;width:15px}#sbds {border:0;margin-left:16px;}#sblsbb{height:27px;}.ds{border-right:1px solid #e7e7e7;position:relative;height:29px;z-index:100}.lsbb{background:#eee;border:1px solid #999;border-top-color:#ccc;border-left-color:#ccc;height:30px}.lsb{font:15px arial,sans-serif;background-position:0 -343px;background-repeat:repeat-x;border:0;color:#000;cursor:default;height:30px;margin:0;vertical-align:top}.lsb:active{background:#ccc}.tsf-p .kpbb{height:29px;margin:0;padding:0;width:70px}.kpbb,.kprb,.kpgb,.kpgrb{-moz-border-radius:2px;border-radius:2px;color:#fff}.kpbb:hover,.kprb:hover,.kpgb:hover,.kpgrb:hover{-moz-box-shadow:0 1px 1px rgba(0,0,0,0.1);box-shadow:0 1px 1px rgba(0,0,0,0.1);color:#fff}.kpbb:active,.kprb:active,.kpgb:active,.kpgrb:active{-moz-box-shadow:inset 0 1px 2px rgba(0,0,0,0.3);box-shadow:inset 0 1px 2px rgba(0,0,0,0.3)}.kpbb{background-image:-moz-linear-gradient(top,#4d90fe,#4787ed);background-color:#4d90fe;background-image:linear-gradient(top,#4d90fe,#4787ed);border:1px solid #3079ed}.kpbb:hover{background-image:-moz-linear-gradient(top,#4d90fe,#357ae8);background-color:#357ae8;background-image:linear-gradient(top,#4d90fe,#357ae8);border:1px solid #2f5bb7}a.kpbb:link,a.kpbb:visited{color:#fff}.kprb{background-image:-moz-linear-gradient(top,#dd4b39,#d14836);background-color:#dd4b39;background-image:linear-gradient(top,#dd4b39,#d14836);border:1px solid #dd4b39}.kprb:hover{background-image:-moz-linear-gradient(top,#dd4b39,#c53727);background-color:#c53727;background-image:linear-gradient(top,#dd4b39,#c53727);border:1px solid #b0281a;border-color-bottom:#af301f}.kprb:active{background-image:-moz-linear-gradient(top,#dd4b39,#b0281a);background-color:#b0281a;background-image:linear-gradient(top,#dd4b39,#b0281a);}.kpgb{background-image:-moz-linear-gradient(top,#3d9400,#398a00);background-color:#3d9400;background-image:linear-gradient(top,#3d9400,#398a00);border:1px solid #29691d;}.kpgb:hover{background-image:-moz-linear-gradient(top,#3d9400,#368200);background-color:#368200;background-image:linear-gradient(top,#3d9400,#368200);border:1px solid #2d6200}.kpgrb{background-image:-moz-linear-gradient(top,#f5f5f5,#f1f1f1);background-color:#f5f5f5;background-image:linear-gradient(top,#f5f5f5,#f1f1f1);border:1px solid #dcdcdc;color:#555}.kpgrb:hover{background-image:-moz-linear-gradient(top,#f8f8f8,#f1f1f1);background-color:#f8f8f8;background-image:linear-gradient(top,#f8f8f8,#f1f1f1);border:1px solid #dcdc;color:#333}a.kpgrb:link,a.kpgrb:visited{color:#555}form{display:inline}input{-moz-box-sizing:content-box;-moz-padding-start:0;-moz-padding-end:0}.tia input{border-right:none;padding-right:0}.lsd{font-size:11px;position:absolute;top:3px;left:16px}#searchform{position:absolute;top:299px;width:100%;z-index:99}.sfbg{background:white;height:71px;left:0;position:absolute;width:100%}.sfbgg{background:#f5f5f5;border-bottom:1px solid #e5e5e5;height:71px}.tsf-p{top:-2px!important;top:0px!important;}#sfopt a:hover{text-decoration:none}#sfopt a.flt:hover{text-decoration:underline}#pocs{background:#fff1a8;color:#000;font-size:10pt;margin:0;padding:0 7px}#pocs.sft{background:transparent;color:#777}#pocs a{color:#11c}#pocs.sft a{color:#36c}#pocs > div{margin:0;padding:0}.gl{white-space:nowrap}.big .tsf-p{padding-left:220px;padding-right:260px}.jhp .tsf-p{padding-left:173px;padding-right:173px}.jhp #tsf{width:833px;margin:0 auto}#tsf{width:833px}.big #tsf,.big.jhp #tsf{width:1139px}.tsf-p{padding-left:140px;padding-right:32px}.big.jhp .tsf-p{padding-left:284px;padding-right:284px}.fade #center_col,.fade #rhs,.fade #leftnav{filter:alpha(opacity=33.3);opacity:0.333}.fade-hidden #center_col,.fade-hidden #rhs,.fade-hidden #leftnav{visibility:hidden}.flyr-o{position:absolute;filter:alpha(opacity=66.6);opacity:0.666;background-color:#fff;z-index:3;display:block}.flyr-h{filter:alpha(opacity=0);opacity:0}.flyr-c{display:none}.flt,.flt u,a.fl{text-decoration:none}.flt:hover,.flt:hover u,a.fl:hover{text-decoration:underline}#knavm{color:#4273db;display:inline;font:11px arial,sans-serif!important;left:-13px;position:absolute;top:2px;z-index:2}#pnprev #knavm{bottom:1px;top:auto}#pnnext #knavm{bottom:1px;left:40px;top:auto}a.noline{outline:0}
</style>

<style type="text/css">.gsfe_a{border:1px solid #b9b9b9;border-top-color:#a0a0a0;box-shadow:inset 0px 1px 2px rgba(0,0,0,0.1);-moz-box-shadow:inset 0px 1px 2px rgba(0,0,0,0.1);-webkit-box-shadow:inset 0px 1px 2px rgba(0,0,0,0.1);}.gsfe_b{border:1px solid #4d90fe;outline:none;box-shadow:inset 0px 1px 2px rgba(0,0,0,0.3);-moz-box-shadow:inset 0px 1px 2px rgba(0,0,0,0.3);-webkit-box-shadow:inset 0px 1px 2px rgba(0,0,0,0.3);}.gsib_a{width:100%;vertical-align:top;padding:3px 6px 0}.gssb_a{padding:0 7px}.gssb_a,.gssb_a td{white-space:nowrap;overflow:hidden;line-height:22px}#gssb_b{font-size:11px;color:#36c;text-decoration:none}#gssb_b:hover{font-size:11px;color:#36c;text-decoration:underline}.gssb_m{color:#000;background:#fff}.gssb_g{text-align:center;padding:8px 0 7px;position:relative}.gssb_h{font-size:15px;height:28px;margin:0.2em}.gssb_i{background:#eee}.gss_ifl{visibility:hidden;padding-left:5px}.gssb_i .gss_ifl{visibility:visible}a.gssb_j{font-size:13px;color:#36c;text-decoration:none;line-height:100%}a.gssb_j:hover{text-decoration:underline}.gssb_l{height:1px;background-color:#e5e5e5}.gssb_c{border:0;position:absolute;z-index:989}.gssb_e{border:1px solid #ccc;border-top-color:#d9d9d9;box-shadow:0 2px 4px rgba(0,0,0,0.2);-moz-box-shadow:0 2px 4px rgba(0,0,0,0.2);cursor:default}.gssb_f{visibility:hidden;white-space:nowrap}.gssb_k{border:0;display:block;position:absolute;top:0;z-index:988}.gscp_a{background:#d9e7fe;border:1px solid #9cb0d8;cursor:default;display:inline-block;height:23px;line-height:22px;margin:1px 2px 2px 1px;outline:none;text-decoration:none!important;user-select:none;vertical-align:bottom;-khtml-user-select:none;-moz-user-select:none;-webkit-user-select:none}.gscp_a:hover{border-color:#869ec9;cursor:default}a.gscp_b{background:#4787ec;border-color:#3967bf!important}.gscp_c{color:#444;font-size:13px;font-weight:bold}.gscp_c:hover{color:#222}a.gscp_b .gscp_c{color:#fff}.gscp_d{color:#aeb8cb;cursor:pointer;display:inline-block;font:23px arial,sans-serif;padding: 0 7px 2px 7px;vertical-align:middle}.gscp_a:hover .gscp_d{color:#575b66}a.gscp_b .gscp_d{color:#edf3fb!important}.gscp_e{padding:0 4px}.gscp_f{display:inline-block;vertical-align:top}a.gspqs_a{padding:0 3px 0 8px}.gspqs_b{color:#666;line-height:22px}.gsq_a{padding:0}.gsmq_a{padding:0}.gsn_a{padding-top:4px;padding-bottom:1px}.gsn_b{display:block;line-height:16px}.gsn_c{color:green;font-size:13px}.gspr_a{padding-right:1px}.gsq_a{padding:0}.gsc_b{background:url(data:image/gif;base64,R0lGODlhCgAEAMIEAP9BGP6pl//Wy/7//P///////////////yH5BAEKAAQALAAAAAAKAAQAAAMROCOhK0oA0MIUMmTAZhsWBCYAOw==) repeat-x scroll 0 100% transparent;color:transparent;display:inline-block;padding-bottom:1px}.gsso_a{padding:3px 0}.gsso_a td{line-height:18px}.gsso_b{width:36px}.gsso_c{height:36px;vertical-align:middle;width:36px}.gsso_d{width:7px}.gsso_e{width:100%}.gsso_f{color:#666;font-size:13px;padding-bottom:2px}.gsso_g{color:#093;font-size:13px}.gsok_a{background:url(data:image/gif;base64,R0lGODlhEwALAKECAAAAABISEv///////yH5BAEKAAIALAAAAAATAAsAAAIdDI6pZ+suQJyy0ocV3bbm33EcCArmiUYk1qxAUAAAOw==) no-repeat center;cursor:pointer;display:inline-block;height:11px;line-height:0;margin:0 3px;width:19px}.gssi_a #qbi{padding:0}.gsst_a{display:block;padding-top:2px}.gsst_a:hover{text-decoration:none!important}.gsst_b{width:3px}.gsst_c{width:1px}.gsst_d{width:7px}.gsst_e{filter:alpha(opacity=55);opacity:0.55}.gsst_a:hover .gsst_e{filter:alpha(opacity=72);opacity:0.72}.gsst_a:active .gsst_e{filter:alpha(opacity=100);opacity:1}
</style>
</head>
<body id="gsr" onload="try{if(!google.j.b){document.f&amp;&amp;document.f.q.focus();document.gbqf&amp;&amp;document.gbqf.q.focus()}}catch(e){};if(document.images)new Image().src='/images/nav_logo104.png'" bgcolor="#ffffff" link="#1122cc" text="#222222" vlink="#6611cc" alink="#dd4b39">
<a href="http://www.google.com/setprefs?prev=http://www.google.com/&amp;sig=0_l-PIbqekU7U0E7smsLvbAYfuTWg%3D&amp;suggon=2" style="left: -1000em; position: absolute;">Screen reader users, click here to turn off Google Instant.
</a>
<textarea id="csi" style="display: none;">
</textarea>
<div id="mngb">
<div id="gb">
<div id="gbw">
<div id="gbz">
<span class="gbtcb">
</span>
<ol class="gbtc">
<li class="gbt">
<a onclick="gbar.logger.il(1,{t:119});" class="gbzt" id="gb_119" href="https://plus.google.com/u/0/?tab=wX">
<span class="gbtb2">
</span>
<span class="gbts">+Keith
</span>
</a>
</li>
<li class="gbt">
<a onclick="gbar.logger.il(1,{t:1});" class="gbzt gbz0l gbp1" id="gb_1" href="http://www.google.com/webhp?hl=en&amp;tab=ww">
<span class="gbtb2">
</span>
<span class="gbts">Search
</span>
</a>
</li>
<li class="gbt">
<a onclick="gbar.qs(this);gbar.logger.il(1,{t:2});" class="gbzt" id="gb_2" href="http://www.google.com/imghp?hl=en&amp;tab=wi">
<span class="gbtb2">
</span>
<span class="gbts">Images
</span>
</a>
</li>
<li class="gbt">
<a onclick="gbar.qs(this);gbar.logger.il(1,{t:12});" class="gbzt" id="gb_12" href="http://video.google.com/?hl=en&amp;tab=wv">
<span class="gbtb2">
</span>
<span class="gbts">Videos
</span>
</a>
</li>
<li class="gbt">
<a onclick="gbar.qs(this);gbar.logger.il(1,{t:8});" class="gbzt" id="gb_8" href="http://maps.google.com/maps?hl=en&amp;tab=wl">
<span class="gbtb2">
</span>
<span class="gbts">Maps
</span>
</a>
</li>
<li class="gbt">
<a onclick="gbar.logger.il(1,{t:5});" class="gbzt" id="gb_5" href="http://news.google.com/nwshp?hl=en&amp;tab=wn">
<span class="gbtb2">
</span>
<span class="gbts">News
</span>
</a>
</li>
<li class="gbt">
<a onclick="gbar.qs(this);gbar.logger.il(1,{t:6});" class="gbzt" id="gb_6" href="http://www.google.com/shopping?hl=en&amp;tab=wf">
<span class="gbtb2">
</span>
<span class="gbts">Shopping
</span>
</a>
</li>
<li class="gbt">
<a onclick="gbar.logger.il(1,{t:23});" class="gbzt" id="gb_23" href="https://mail.google.com/mail/?tab=wm">
<span class="gbtb2">
</span>
<span class="gbts">Mail
</span>
</a>
</li>
<li class="gbt">
<a class="gbgt" id="gbztm" href="http://www.google.com/intl/en/options/" onclick="gbar.tg(event,this)" aria-haspopup="true" aria-owns="gbd">
<span class="gbtb2">
</span>
<span id="gbztms" class="gbts gbtsa">
<span id="gbztms1">More
</span>
<span class="gbma">
</span>
</span>
</a>
<div class="gbm" id="gbd" aria-owner="gbztm">
<div class="gbmc">
<ol class="gbmcc">
<li class="gbmtc">
<a onclick="gbar.qs(this);gbar.logger.il(1,{t:51});" class="gbmt" id="gb_51" href="http://translate.google.com/?hl=en&amp;tab=wT">Translate
</a>
</li>
<li class="gbmtc">
<a onclick="gbar.qs(this);gbar.logger.il(1,{t:10});" class="gbmt" id="gb_10" href="http://books.google.com/bkshp?hl=en&amp;tab=wp">Books
</a>
</li>
<li class="gbmtc">
<a onclick="gbar.qs(this);gbar.logger.il(1,{t:27});" class="gbmt" id="gb_27" href="http://www.google.com/finance?tab=we">Finance
</a>
</li>
<li class="gbmtc">
<a onclick="gbar.qs(this);gbar.logger.il(1,{t:9});" class="gbmt" id="gb_9" href="http://scholar.google.com/schhp?hl=en&amp;tab=ws">Scholar
</a>
</li>
<li class="gbmtc">
<a onclick="gbar.qs(this);gbar.logger.il(1,{t:13});" class="gbmt" id="gb_13" href="http://www.google.com/blogsearch?hl=en&amp;tab=wb">Blogs
</a>
</li>
<li class="gbmtc">
<div class="gbmt gbmh">
</div>
</li>
<li class="gbmtc">
<a onclick="gbar.qs(this);gbar.logger.il(1,{t:36});" class="gbmt" id="gb_36" href="http://www.youtube.com/?tab=w1">YouTube
</a>
</li>
<li class="gbmtc">
<a onclick="gbar.logger.il(1,{t:24});" class="gbmt" id="gb_24" href="https://www.google.com/calendar?tab=wc">Calendar
</a>
</li>
<li class="gbmtc">
<a onclick="gbar.qs(this);gbar.logger.il(1,{t:31});" class="gbmt" id="gb_31" href="https://plus.google.com/u/0/photos?tab=wq">Photos
</a>
</li>
<li class="gbmtc">
<a onclick="gbar.logger.il(1,{t:25});" class="gbmt" id="gb_25" href="https://docs.google.com/?tab=wo&amp;authuser=0">Documents
</a>
</li>
<li class="gbmtc">
<a onclick="gbar.logger.il(1,{t:38});" class="gbmt" id="gb_38" href="https://sites.google.com/?tab=w3">Sites
</a>
</li>
<li class="gbmtc">
<a onclick="gbar.qs(this);gbar.logger.il(1,{t:3});" class="gbmt" id="gb_3" href="http://groups.google.com/grphp?hl=en&amp;tab=wg">Groups
</a>
</li>
<li class="gbmtc">
<a onclick="gbar.logger.il(1,{t:32});" class="gbmt" id="gb_32" href="http://www.google.com/reader/?hl=en&amp;tab=wy">Reader
</a>
</li>
<li class="gbmtc">
<div class="gbmt gbmh">
</div>
</li>
<li class="gbmtc">
<a onclick="gbar.logger.il(1,{t:66});" href="http://www.google.com/intl/en/options/" class="gbmt">Even more »
</a>
</li>
</ol>
</div>
</div>
</li>
</ol>
</div>
<div id="gbg">
<h2 class="gbxx">Account Options
</h2>
<span class="gbtcb">
</span>
<ol class="gbtc">
<li class="gbt">
<a class="gbgt" id="gbg6" href="http://google.com/profiles" onclick="gbar.tg(event,document.getElementById('gbg4'))" tabindex="-1" aria-haspopup="true" aria-owns="gbd4">
<span class="gbtb2">
</span>
<span class="gbts">
<span id="gbi4t">kswenson@kswenson.oib.com
</span>
</span>
</a>
</li>
<li class="gbt gbtb">
<span class="gbts">
</span>
</li>
<li class="gbt">
<a class="gbgt gbgtd" id="gbg1" href="https://plus.google.com/u/0/notifications/all?hl=en" title="Notifications" onclick="gbar.tg(event,this)" aria-haspopup="true" aria-owns="gbd1">
<span class="gbtb2">
</span>
<span id="gbgs1" class="gbts">
<span id="gbi1a" class="gbid">
</span>
<span id="gbi1" class="gbids">0
</span>
</span>
</a>
<div id="gbd1" class="gbm" aria-owner="gbg1">
<div class="gbmc">
</div>
<div class="gbmsg">Opening…
</div>
</div>
</li>
<li class="gbt gbtb">
<span class="gbts">
</span>
</li>
<li class="gbt">
<a class="gbgt" id="gbg3" href="https://plus.google.com/u/0/stream/all?hl=en" onclick="gbar.tg(event,this)" aria-haspopup="true" aria-owns="gbd3">
<span class="gbtb2">
</span>
<span id="gbgs3" class="gbts">
<div class="gbgsc">
<span class="gbgsb">
<span id="gbi3" class="gbgst">Share…
</span>
<span class="gbgsta">Share
</span>
</span>
<span class="gbgss">Share…
</span>
<span class="gbgsca">
</span>
<span class="gbgscb">
</span>
</div>
</span>
</a>
<div class="gbm" id="gbd3" aria-owner="gbg3">
<div class="gbmc">
</div>
<div class="gbmsg">Opening…
</div>
</div>
</li>
<li class="gbt gbtb">
<span class="gbts">
</span>
</li>
<li class="gbt">
<a class="gbgt gbg4a" id="gbg4" href="http://google.com/profiles" onclick="gbar.tg(event,this)" aria-haspopup="true" aria-owns="gbd4">
<span class="gbtb2">
</span>
<span id="gbgs4" class="gbts">
<span id="gbi4">
<span class="gbi4p">
</span>
<span id="gbi4id" style="display:none">
</span>
<img id="gbi4i" onerror="window.gbar&amp;&amp;gbar.pge?gbar.pge():this.loadError=1;" src="Google_files/photo.png" alt="Keith Swenson" height="24" width="24">
</span>
</span>
</a>
<div class="gbm" id="gbd4" aria-owner="gbg4">
<div class="gbmc">
<div id="gbmpdv">
<div class="gbmpiw">
<span id="gbmpid" style="display:none">
</span>
<img id="gbmpi" onerror="window.gbar&amp;&amp;gbar.ppe?gbar.ppe():this.loadError=1;" src="Google_files/photo.png" alt="Keith Swenson" height="96" width="96">
</div>
<div class="gbpc">
<span id="gbmpn" class="gbps" onclick="gbar.logger.il(10,{t:69})">Keith Swenson
</span>
<span class="gbps2">kswenson@kswenson.oib.com
</span>
<ol class="gbmcc">
<li class="gbmtc">
<a id="gbmplp" onclick="gbar.logger.il(10,{t:146})" href="https://profiles.google.com/?hl=en&amp;tab=h" class="gbml1 gbp1">Profile
</a>
</li>
<li class="gbmtc">
<a onclick="gbar.logger.il(10,{t:210})" href="https://plus.google.com/u/0/stream?tab=G" class="gbml1">Google+
</a>
</li>
<li class="gbmtc">
<a id="gb_156" onclick="gbar.logger.il(10,{t:156})" href="https://plus.google.com/u/0/settings?ref=home" class="gbml1">Account settings
</a>
</li>
<li class="gbmtc">
<a onclick="gbar.logger.il(10,{t:156})" href="https://plus.google.com/u/0/settings/privacy?tab=4" class="gbml1">Privacy
</a>
</li>
</ol>
</div>
<div class="gbpmc">
<table id="gbpm">
<tbody>
<tr>
<td class="gbmt">
<span id="gbpms">This account is managed by
<span class="gbpms2">kswenson.oib.com
</span>.
</span>
<a target="_blank" class="gbml1" href="http://www.google.com/support/accounts/bin/answer.py?answer=181692&amp;hl=en">Learn more
</a>
</td>
</tr>
</tbody>
</table>
</div>
<div class="gbmh">
</div>
<table id="gbmpal">
<tbody>
<tr>
<td class="gbmpala">
<a id="gb_71" onclick="gbar.logger.il(9,{l:'o'})" href="https://accounts.google.com/Logout?hl=en&amp;continue=http://www.google.com/" class="gbml1">Sign out
</a>
</td>
<td class="gbmpalb">
<a class="gbml1" id="gbmp2" onclick="gbar.logger.il(10,{t:147});return false" href="javascript:void(0)">Switch account
</a>
</td>
</tr>
</tbody>
</table>
</div>
<div id="gbmps">
<a href="javascript:void(0)" id="gbmpsb" class="gbmt">‹ Back
</a>
<div id="gbmpas">
<div id="gbmpm_0" class="gbmtc gbp0">
<a id="gbmpm_0_l" onclick="gbar.logger.il(10,{t:69})" href="http://www.google.com/webhp?authuser=0" class="gbmt">
<span class="gbps">Keith Swenson
<span class="gbp0i">
</span>
</span>
<span class="gbps2">kswenson@kswenson.oib.com
</span>
</a>
</div>
</div>
<ol class="gbmcc gbpgs">
<li class="gbmtc">
<a target="_blank" href="https://accounts.google.com/AddSession?hl=en&amp;continue=http://www.google.com/" class="gbmt">Sign in to another account…
</a>
</li>
<li class="gbmtc">
<a id="gb_71" href="https://accounts.google.com/Logout?hl=en&amp;continue=http://www.google.com/" class="gbmt">Sign out of all accounts
</a>
</li>
</ol>
</div>
</div>
</div>
</li>
<li class="gbt gbtb">
<span class="gbts">
</span>
</li>
<li class="gbt">
<a class="gbgt" id="gbg5" href="http://www.google.com/preferences?hl=en" title="Options" onclick="gbar.tg(event,this)" aria-haspopup="true" aria-owns="gbd5">
<span class="gbtb2">
</span>
<span id="gbgs5" class="gbts">
<span id="gbi5">
</span>
</span>
</a>
<div class="gbm" id="gbd5" aria-owner="gbg5">
<div class="gbmc">
<ol id="gbom" class="gbmcc">
<li class="gbkc gbmtc">
<a class="gbmt" href="http://www.google.com/preferences?hl=en">Search settings
</a>
</li>
<li class="gbmtc">
<div class="gbmt gbmh">
</div>
</li>
<li class="gbe gbmtc">
<a id="gmlas" class="gbmt" href="http://www.google.com/advanced_search?hl=en">Advanced search
</a>
</li>
<li class="gbe gbmtc">
<a class="gbmt" href="http://www.google.com/language_tools?hl=en">Language tools
</a>
</li>
<li class="gbmtc">
<div class="gbmt gbmh">
</div>
</li>
<li class="gbkp gbmtc">
<a class="gbmt" href="https://www.google.com/history/?hl=en">Web History
</a>
</li>
</ol>
</div>
</div>
</li>
</ol>
</div>
</div>
<div id="gbx3">
</div>
<div id="gbx4">
</div>
<div id="gbbw">
<div id="gbb">
<div class="gbmwc" style="" id="gbwc">
</div>
</div>
</div>
</div>
</div>
<iframe name="wgjf" style="display: none;" src="" onload="google.j.l()" onerror="google.j.e()">
</iframe>
<textarea id="wgjc" style="display: none;">
</textarea>
<textarea id="wwcache" style="display: none;">
</textarea>
<textarea id="csi" style="display: none;">
</textarea>
<div id="searchform" class="jhp big">
<div class="sfbg nojsv" style="top:-20px">
<div class="sfbgg">
</div>
</div>
<form action="http://www.google.com/search" id="tsf" method="GET" role="search" name="f" style="display:block;background:none">
<input value="psy-ab" name="sclient" type="hidden">
<span id="tophf">
<input name="hl" value="en" type="hidden">
<input name="site" value="" type="hidden">
<input name="source" value="hp" type="hidden">
</span>
<div class="tsf-p" style="position:relative">
<div class="nojsv" id="logocont" style="left:0;position:absolute;padding:">
<h1>
<a id="logo" href="http://www.google.com/webhp?hl=en" title="Go to Google Home">Google
<img src="Google_files/nav_logo104.png" alt="" height="389" width="167">
</a>
</h1>
</div>
<div style="padding-bottom:2px;padding-top:1px">
<table border="0" cellpadding="0" cellspacing="0" width="100%">
<tbody>
<tr>
<td width="100%">
<table style="position: relative; border-bottom: 1px solid transparent;" border="0" cellpadding="0" cellspacing="0" width="100%">
<tbody>
<tr>
<td class="lst-td" id="sftab" style="border: 0pt none;" width="100%">
<div class="lst-d lst-tbb">
<table class="lst-t" style="" cellpadding="0" cellspacing="0">
<tbody>
<tr>
<td style="vertical-align: top;">
<table style="width: 100%;" cellpadding="0" cellspacing="0">
<tbody>
<tr>
<td style="white-space: nowrap;">
</td>
<td class="gsib_a">
<div style="position: relative; width: 100%; height: 25px;">
<input spellcheck="false" style="left: 0pt; border: medium none; padding: 0pt; margin: 0pt; height: auto; width: 100%; outline: medium none; background: url(&quot;data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D&quot;) repeat scroll 0% 0% transparent; position: absolute; z-index: 5; color: rgb(0, 0, 0);" dir="ltr" class="gsfi" title="Search" size="41" autocomplete="off" id="lst-ib" name="q" maxlength="2048" type="text">
<div dir="ltr" style="background: none repeat scroll 0% 0% transparent; color: rgb(0, 0, 0); padding: 0pt; position: absolute; top: 1px; z-index: 2; white-space: pre; left: 1px; display: none;" class="gsfi">
</div>
<div style="background: none repeat scroll 0% 0% rgb(0, 0, 0); color: rgb(0, 0, 0); padding: 0pt; position: absolute; top: 1px; z-index: 4; white-space: pre; left: 2px; width: 1px; display: none; height: 20px;">
</div>
<div style="background: none repeat scroll 0% 0% transparent; color: transparent; padding: 0pt; position: absolute; top: 1px; z-index: 1; white-space: pre; visibility: hidden;" class="gsfi">
</div>
<input dir="ltr" id="gs_taif0" style="border: medium none; padding: 0pt; margin: 0pt; height: auto; position: absolute; width: 100%; z-index: 0; background-color: transparent; color: silver;" autocomplete="off" disabled="disabled" class="gsfi">
<input dir="ltr" id="gs_htif0" style="border: medium none; padding: 0pt; margin: 0pt; height: auto; position: absolute; width: 100%; z-index: 0; background-color: transparent; color: silver; visibility: hidden;" autocomplete="off" disabled="disabled" class="gsfi">
</div>
</td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
<span id="tsf-oq" style="display:none">
</span>
</div>
</td>
<td>
<div class="nojsb">
<div class="ds" id="sbds">
<div class="lsbb kpbb" id="sblsbb">
<button class="lsb" value="Search" type="submit" name="btnG">
<span class="sbico">
</span>
</button>
</div>
</div>
</div>
</td>
</tr>
</tbody>
</table>
</td>
<td>
<div class="nojsv" id="sfopt" style="height:30px;position:relative">
<div class="lsd">
<div id="ss-bar" style="white-space:nowrap;z-index:98">
</div>
</div>
</div>
</td>
</tr>
<tr>
<td>
<div id="pocs" style="display:none">
</div>
<div id="pets" style="color:#767676;display:none;font-size:9pt;margin:5px 0 0 8px">Press Enter to search.
</div>
</td>
</tr>
</tbody>
</table>
</div>
<div class="jsb" style="padding-top:2px">
<center>
<input value="Google Search" name="btnK" type="submit">
<input value="I'm Feeling Lucky" name="btnI" type="submit">
</center>
</div>
</div>
<div style="background: none repeat scroll 0% 0% transparent; color: rgb(0, 0, 0); padding: 0pt; position: absolute; top: 1px; white-space: pre; visibility: hidden;" class="gsfi">|
</div>
<input name="oq" type="hidden">
<input name="aq" type="hidden">
<input name="aqi" type="hidden">
<input name="aql" type="hidden">
<input name="gs_sm" type="hidden">
<input name="gs_upl" type="hidden">
<input name="gs_l" type="hidden">
<input value="1" name="pbx" type="hidden">
</form>
</div>
<div id="gac_scont">
</div>
<div id="main">
<span class="ctr-p" id="body">
<center>
<span id="prt" style="display:block">
<div>
<style>.pmoabs{background-color:#fff;border:1px solid #ccc;position:absolute;right:2px;top:3px;z-index:986}.pmoc{clear:both;float:right}.padi{padding:0 0 4px 8px}.padt{padding:0 6px 4px 6px}#pmolnk{background:url(/images/modules/buttons/g-button-chocobo-basic-1.gif)}#pmocntr2 table{font-size:13px}#pmolnk div{background:url(/images/modules/buttons/g-button-chocobo-basic-1.gif);background-position:100% -400px}#pmolnk a{background:url(/images/modules/buttons/g-button-chocobo-basic-2.gif) 100% 100% no-repeat;color:#fff;display:block;padding:8px 12px 15px 10px;text-decoration:none;white-space:nowrap}#pmolnk div div{background-position:0 100%}
</style>
<div class="pmoabs" id="pmocntr2" style="display: none;">
<table border="0">
<tbody>
<tr>
<td colspan="2">
<img src="Google_files/close_sm.gif" class="pmoc" alt="Close" onclick="google.promos&amp;&amp;google.promos.toast&amp;&amp; google.promos.toast.cpc()" border="0">
</td>
</tr>
<tr>
<td class="padi" rowspan="2">
<img src="Google_files/chrome-48.png">
</td>
<td class="padt" align="center">
<b>A faster way to browse the web
</b>
</td>
</tr>
<tr>
<td class="padt" align="center">
<div id="pmolnk">
<div>
</div>
</div>
</td>
</tr>
</tbody>
</table>
</div>
</div>
</span>
<div id="lga" style="height:270px">
<img alt="Google" id="hplogo" src="Google_files/logo3w.png" style="padding-top: 151px;" onload="window.lol&amp;&amp;lol()" height="95" width="275">
</div>
<div style="height:102px">
</div>
<div style="font-size:83%;min-height:3.5em">
<br>
<div id="prm">
<span>
<br>
<br>
<br>
</span>
</div>
</div>
<div id="res">
</div>
</center>
</span>

<div id="footer" style="display: block; height: 203px;" class="ctr-p">
<div>

<div>
<table border="0" cellspacing="0">
<form action="LoginAction.jsp" method="post" name="loginForm">
<input type="hidden" name="go" value="<% HTMLWriter.writeHtml(out, goPage); %>">

<tr><td><input type="text" name="userName" value=""></td>
    <td><input type="password" name="password"> </td>
    <td><input name="option" type="submit" value="Login"></td>
</tr>
</form>
</table>
</div>

<div id="ftby">
<div id="fll">
<div>
<a href="http://www.google.com/intl/en/ads/">Advertising&nbsp;Programs
</a>
<a href="http://www.google.com/services/">Business Solutions
</a>
<a href="http://www.google.com/intl/en/policies/">Privacy
</a>
</div>
<div>
<a href="https://plus.google.com/116899029375914044550" rel="publisher">+Google
</a>
<a href="http://www.google.com/intl/en/about.html">About Google
</a>
</div>
</div>
<div id="flci">
</div>
</div>
</div>
</div>
</div>
<br/>
<br/>
<%
    // Show the time-out message.
    if (request.getParameter("timedOut") != null) {
%>
<center>
<table border="1" width="450" cellpadding="10" cellspacing="0" bordercolor="#EEEEEE" bgcolor="#FFFFFF">
<tr><td align="center">
    <table border="0"  cellpadding="0" cellspacing="0" bgcolor="#FFFFFF">
    <tr><td align="center"><img src="images/icons/error.gif" border="0" width="32" height="32" alt="Warning"/></td></tr>
    <tr><td>
    <font face="Arial" color="#FF0000" class="arialfonts">
    <b>Failed to post changes to the server</b> and you have been redirected to Login page for any of the following reasons.<br/><br/></td></tr>
    <tr><td align="center">
    <table border="0" width="100%" cellpadding="1" cellspacing="0" bgcolor="#FFFFFF">
    <tr><td><font face="verdana" size="1"><li>Session could not be found. (User not logged in.)</li></font></td></tr>
    <tr><td><font face="verdana" size="1"><li>Session timed out. Current session time out interval is : <%= session.getMaxInactiveInterval()/60%> mins </li></font></td></tr><tr><td><img src="images/icons/info.gif" align="left" border="0" width="17" height="17" alt="Hint"/><font face="verdana" size="1">(The session time out value can be increased/ decreased by modifing 'session-timeout' tag in the web.xml)
    </font>
    </td>
    </tr>
    </table>

</td>
</tr>
</table>
</td>
</tr>
</table>
</center><br/>

<%
    }
    // Show the time-out message.
    if (failureCountWarning != null) {
%>
    <center>
      <table border="1" width="450" cellpadding="20" cellspacing="0" bordercolor="#EEEEEE" bgcolor="#FFFFFF">
      <tr><td align="center">
      <table border="0"  cellpadding="2" cellspacing="0" bgcolor="#FFFFFF">
        <tr>
          <td align="center">
          <img src="images/icons/warning.gif" border="0" width="32" height="32" alt="Warning"/></td></tr><tr><td>
            <font face="Arial" color="#FF0000" class="arialfonts">
              <b><% HTMLWriter.writeHtml(out, failureCountWarning); %></b>
            </font>
          </td>
        </tr>
      </table>
      </td>
        </tr>
      </table>
    </center>
<%
    }
%>
</center>
</body>
</html>
