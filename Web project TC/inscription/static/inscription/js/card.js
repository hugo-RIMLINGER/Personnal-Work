var valIntervenant  = document.getElementById('cardIntervenant');
var valPostulant = document.getElementById('cardPostulant');

var arrayval = [valIntervenant,valPostulant];
arrayval.forEach((val) => {
  val.onmouseover = function() {
    // val.style.border = '2px solid orange';
    // val.style.boxShadow = '0px 4px 5px #000000';
  };
  val.onmouseout = function() {
    val.style.border = 'none';
    val.style.boxShadow = 'none';
  };
});
