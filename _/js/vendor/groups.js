!function i(o,s,u){function f(e,t){if(!s[e]){if(!o[e]){var r="function"==typeof require&&require;if(!t&&r)return r(e,!0);if(d)return d(e,!0);var n=new Error("Cannot find module '"+e+"'");throw n.code="MODULE_NOT_FOUND",n}var a=s[e]={exports:{}};o[e][0].call(a.exports,function(t){return f(o[e][1][t]||t)},a,a.exports,i,o,s,u)}return s[e].exports}for(var d="function"==typeof require&&require,t=0;t<u.length;t++)f(u[t]);return f}({1:[function(t,e,r){groupChangeListeners=[],window.groupChanged=function(t){groupChangeListeners.push(t)},$(function(){var a="antoraGroups",t=function(t){for(var e=t+"=",r=decodeURIComponent(document.cookie).split(";"),n=0;n<r.length;n++){for(var a=r[n];" "==a.charAt(0);)a=a.substring(1);if(0==a.indexOf(e))return a.substring(e.length,a.length)}return""}(a),i={},o={},s={};function u(t,e){i[t]=e,function(t,e,r){r||(r=365);var n=new Date;n.setTime(n.getTime()+24*r*60*60*1e3);var a="expires="+n.toGMTString();document.cookie=t+"="+e+";"+a+";path=/"}(a,JSON.stringify(i)),$("select").has("option[value="+e+"]").val(e);for(var r=0;r<o[t].length;r++){var n=o[t][r];n==e?$("."+e).show():$("."+n).hide()}$("dl.tabbed").each(function(){$(this).find("dt").each(function(){var t=$(this);d(t)==e&&f(t)})});for(r=0;r<groupChangeListeners.length;r++)groupChangeListeners[r](e,t,o)}function f(t){var e=t.parent("dl");e.find(".current").removeClass("current").next("dd").removeClass("current").hide(),t.addClass("current");var r=t.next("dd").addClass("current").show();e.css("height",t.height()+r.height())}function d(t){var e=t.next("dd").find("pre").attr("class");if(e)for(var r=e.split(" "),n=new RegExp("^group-.*"),a=0;a<r.length;a++)if(n.test(r[a]))return r[a];return"group-"+t.find("a").text().toLowerCase()}""!=t&&(i=JSON.parse(t)),$(".tabset dl").each(function(){var t=$(this);t.addClass("tabbed");var e=t.find("dt");e.each(function(t){var e=$(this);e.html('<a href="#tab'+t+'">'+e.text()+"</a>")}),t.find("dd").each(function(t){var e=$(this);e.hide(),e.find("blockquote").length&&e.addClass("has-note")}),f(e.first()),e.first().addClass("first"),e.last().addClass("last")}),$(".supergroup").each(function(){var e=$(this).attr("name").toLowerCase(),t=$(this).find(".group"),r=i[e];r||(r="group-"+t.first().text().toLowerCase(),i[e]=r),o[e]=[],t.each(function(){var t="group-"+$(this).text().toLowerCase();o[e].push(t),s[t]=e}),u(e,r),$(this).on("change",function(){u(e,this.value)})}),$("dl.tabbed dt a").click(function(t){t.preventDefault();var e=$(this).parent("dt"),r=(e.parent("dl"),d(e)),n=s[r];n?u(n,r):f(e)})})},{}]},{},[1]);