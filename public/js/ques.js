jQuery(function($) {

  $("form#ques").submit(function(){

      var sum = 0;
      $("input:radio:checked").each(function(i){
        sum += 1;
        //alert(i + "/" + $(this).val());
      });

      //alert(sum)

      if (sum == 3) {
        return true;
      }

      else {
      	alert('回答していない項目があります。')
        return false;
      }

  })

  $("form#b_ques").submit(function(){
  		
      uid = $("#uid").val()
      twitter_use = $("#twitter_use").val();
      flickr_use = $("#flickr_use").val();
      bkm_use = $("#bkm_use").val();

      var sum = 0;
      $("input:radio:checked").each(function(i){
        sum += 1;
        //alert(i + "/" + $(this).val());
      });

      alert(sum)
      
      if ((twitter_use == "0") && (flickr_use == "0") && (bkm_use == "0")){
			count = 103;
	      
      } else if (((twitter_use == "0") && (flickr_use == "0")) || ((twitter_use == "0") && (bkm_use == "0"))) {

			count = 73;
      	
      } else if ((bkm_use == "0") && (flickr_use == "0")) {

	      	count = 74;
	      	
      }  else if ((bkm_use == "0") || (flickr_use == "0")) {

			count = 44;
      	
      }  else if (twitter_use == "0") {

	      	count = 43;	
      	
      }
      
      
	  if (sum == count) {
	        return true;
	  } else {
	      	//alert('回答していない項目があります。')
	        return false;
	  }


  })

  $("form#a_ques").submit(function(){

      uid = $("#uid").val()
      twitter_use = $("#twitter_use").val();
      flickr_use = $("#flickr_use").val();
      bkm_use = $("#bkm_use").val();  	
      
      alert(twitter_use);

      var sum = 0;
      $("input:radio:checked").each(function(i){
        sum += 1;
        //alert(i + "/" + $(this).val());
      });

      alert(sum)
      
      if ((twitter_use == "0") && (flickr_use == "0") && (bkm_use == "0")){
			count = 107;
	      
      } else if ((twitter_use == "0") && (bkm_use == "0")) {

			count = 79;
      	
      } else if (((twitter_use == "0") && (flickr_use == "0")) || ((bkm_use == "0") && (flickr_use == "0"))) {

	      	count = 79;
	      	
      }  else if ((bkm_use == "0") || (flickr_use == "0")) {

			count = 51;
      	
      }  else if (twitter_use == "0") {

	      	count = 51;	
      	
      }
      
      alert(count)
      
      
	  if (sum == count) {
	        //alert("ok");
            //return false;
            return true;
	  } else {
	      	alert('回答していない項目があります。')
	        return false;
	  }



  })

});