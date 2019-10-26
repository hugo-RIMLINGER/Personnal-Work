$(document).ready(function(){
  $("#cardPostulant").mouseenter(function(){
    $("#cardPostulant").animate({width: '95%'},200);
  });
  $("#cardPostulant").mouseleave(function(){
    $("#cardPostulant").animate({width: '90%'},200);
  });
});

$(document).ready(function(){
  $("#cardIntervenant").mouseenter(function(){
    $("#cardIntervenant").animate({width: '95%'},100);
  });
  $("#cardIntervenant").mouseleave(function(){
    $("#cardIntervenant").animate({width: '90%'},100);
  });
});
