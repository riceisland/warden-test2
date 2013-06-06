jQuery(function($) {

  $("form#b_ques").submit(function(){
  		
    uid = $("#uid").val()


      var sum = 0;
      $("input:radio:checked").each(function(i){
        sum += 1;
        //alert(i + "/" + $(this).val());
      });

      //alert(sum)

      if (sum == 103) {
        return true;
      }

      else {
      	alert('回答していない項目があります。')
        return false;
      }

  })

  $("form#a_ques").submit(function(){
  		

      var sum = 0;
      $("input:radio:checked").each(function(i){
        sum += 1;
        //alert(i + "/" + $(this).val());
      });

      alert(sum)

      if (sum == 108) {
        return true;
      }

      else {
      	alert('回答していない項目があります。')
        return false;
      }

  })

});