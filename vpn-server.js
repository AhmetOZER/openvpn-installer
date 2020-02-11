var getUrlParameter = function getUrlParameter(sParam) {
    var sPageURL = decodeURIComponent(window.location.search.substring(1)),
        sURLVariables = sPageURL.split('&'),
        sParameterName,
        i;
    for (i = 0; i < sURLVariables.length; i++) {
        sParameterName = sURLVariables[i].split('=');
        if (sParameterName[0] === sParam) {
            return sParameterName[1] === undefined ? true : sParameterName[1];
        }
    }
};
function download(filename, text) {
  var element = document.createElement('a');
  element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text));
  element.setAttribute('download', filename);
  element.style.display = 'none';
  document.body.appendChild(element);
  element.click();
  document.body.removeChild(element);
}
var ipadd = getUrlParameter('ip');
var dosya;
var shutdown;
console.log(ipadd);
var dcr = function(obj)
{
  var key =  $('#pass').val();
  var transithmac = obj.substring(0, 64);
  var transitencrypted = obj.substring(64);
  var decryptedhmac = CryptoJS.HmacSHA256(transitencrypted, CryptoJS.SHA256(key)).toString();
  if (transithmac == decryptedhmac) {
    shutdown = CryptoJS.HmacSHA256(transitencrypted, CryptoJS.SHA256(key+"shutdown")).toString();
    return CryptoJS.AES.decrypt(transitencrypted, key).toString(CryptoJS.enc.Utf8);
  } else {
    $("#status").html("Password is incorrect");
    $("#status").show()
    $(".loading").hide()
  }
};

function showkeyfnk() { $("#result").toggle(); }

function downloadfnk() { download("vpn.ovpn", dosya); }

function vpnform() {
  $(".loading").show()
  $(".after").hide()
  $("#result").hide()
  $("#status").hide()
  var key =  $('#pass').val();
  if (key.length == '11') {
    console.log("Keylenght ok");
  } else {
    if (key.length == '0') {
      $("#status").html("Please write password.");
      $("#status").show()
      $(".loading").hide()
    } else {
      $("#status").html("Your password has missing characters.");
      $("#status").show()
      $(".loading").hide()
    }
    return;
  }
  var ip =  $('#ip').val();
  $.ajax({
    type: 'POST',
    url:'https://ahmetozer.herokuapp.com/projects/vpn-proxy.php',
    data: "ip="+ip,
    success: function(data, textStatus, request){
      dosya = dcr(data);
          if (dosya) {
          $(".after").toggle();
          $("#result").html(dosya);
          $(".loading").hide()
        }
      },
    error: function(jqXHR, textStatus, errorThrown) {
      if (jqXHR.status == '404') {
        $("#status").html("Your vpn server key service not working.Type <code>./vpn.sh keyservice</code> command to the terminal to start the service");
        $("#status").show()
        $(".loading").hide()
      } else {
        $("#status").html("Sory for this error. Please report <a src='https://twitter.com/ahmetozer_org'>@ahmetozer_org</a>.");
        $("#status").show()
        $(".loading").hide()
      }
    }
  });
}


function shutdownfnk() {
  $(".loading").show()
  var ip =  $('#ip').val();
  $.ajax({
    type: 'POST',
    url:'https://ahmetozer.herokuapp.com/projects/vpn-proxy.php',
    data:  {ip: ip, shutdown: shutdown},
    success: function(data, textStatus, request){
      $("#status").html("Please write password.");
      },
    error: function(jqXHR, textStatus, errorThrown) {
      if (jqXHR.status == '404') {
        $("#status").html("Your vpn server key service stopped.If you want to access the key again later, type <code>./vpn.sh keyservice</code> into the terminal");
        $("#status").show()
        $(".loading").hide()
        $(".after").hide()
        $("#result").hide()
      } else {
        $("#status").html("Sory for this error. Please report <a src='https://twitter.com/ahmetozer_org'>@ahmetozer_org</a>.");
        $("#status").show()
        $(".loading").hide()
        $(".after").hide()
        $("#result").hide()
      }
    }
  });
}

function installcommandgenerator() {
  var eporttype = document.getElementById("porttype");
  var sporttype = eporttype.options[eporttype.selectedIndex].value;

  var edevicetype = document.getElementById("devicetype");
  var sdevicetype = edevicetype.options[edevicetype.selectedIndex].value;

  var sportnumber = document.getElementById("portnumber").value;
  document.getElementById('command').innerText = "sudo ./vpn.sh fast-install "+sporttype+" "+sportnumber+" "+sdevicetype;
}

if (typeof ipadd !== 'undefined') {
   if (/^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/.test(ipadd)) {
     $('#ip').val(ipadd);
      $('#pass').focus();
     }
   }
//});
/*$("#ShowKey").click(function(){
        $("#result").toggle();
});
$("#Download").click(function(){
        download("vpn.ovpn", dosya);
});
//$( "#vpnform" ).submit(function( event ) {
*/
