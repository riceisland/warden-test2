jQuery(function($) {

    $('#columns').vgrid({
    	easing: "easeOutQuint",
		useLoadImageEvent: true,
		useFontSizeListener: true,
		time: 400,
		delay: 20,
		wait: 500,
		fadeIn: {
			time: 500,
			delay: 50
		}
    		
    });

  if (location.pathname == "/main") {   
    if($("div.pin").size() == 0) {

    	timer = setInterval(function(){

			    $.ajax({
			      url: "/individual",
			      type: 'GET',
			      cache: 'false',
			      timeout: 10000,
			      data: $(this).serialize(),
			      error: function(){
			      	alert("error")
			      	  $('#columns').vgrid({
    	                easing: "easeOutQuint",
		                useLoadImageEvent: true,
		                useFontSizeListener: true,
		                time: 20000,
		                delay: 20,
		                wait: 500,
		                fadeIn: {
			              time: 500,
			              delay: 50
		                }
    		          });
			      },
			      success: function(str){
			      	
			      	$("img#loading").fadeOut(300).queue( function() {this.remove()});
			      	
			        if(str == "logout"){
			          location.href = ("/")
			        }
			        else{
			      
			          $("#columns").append(str);
			          
			          $('#columns').vgrid({
    	                easing: "easeOutQuint",
		                useLoadImageEvent: true,
		                useFontSizeListener: true,
		                time: 400,
		                delay: 20,
		                wait: 500,
		                fadeIn: {
			              time: 500,
			              delay: 50
		                }
    		          });
			        }
			      }
			    });
    		  	
    		  	if($("div.pin").size() > 6) {
    		  		clearInterval(timer)
    		  	}
   	
    	},15000);	
    } 
  }
	
    $(function(){
    	setInterval(function(){
    		$("div.pin:first").fadeOut(3000).queue(
    		  function(){
    		  	this.remove();

			    $.ajax({
			      url: "/individual",
			      type: 'GET',
			      data: 'count=1',
			      cache: 'false',
			      timeout: 10000,
			      data: $(this).serialize(),
			      error: function(){
			      	alert("error")
			      	  $('#columns').vgrid({
    	                easing: "easeOutQuint",
		                useLoadImageEvent: true,
		                useFontSizeListener: true,
		                time: 400,
		                delay: 20,
		                wait: 500,
		                fadeIn: {
			              time: 500,
			              delay: 50
		                }
    		          });
			      },
			      success: function(str){
			      	//alert(str)
			      	//var dataset = JSON.parse(str);
			        if(str == "logout"){
			          location.href = ("/")
			        }
			        else{
			      
			          $("#columns").append(str);
			          
			          $('#columns').vgrid({
    	                easing: "easeOutQuint",
		                useLoadImageEvent: true,
		                useFontSizeListener: true,
		                time: 400,
		                delay: 20,
		                wait: 500,
		                fadeIn: {
			              time: 500,
			              delay: 50
		                }
    		          });
			        }
			      }
			    });
    		  	

    		    
    		  });
    	}, 20000);
    });
	
//スニペットを作ろう編, evernote関連 
    $('#plain').each(function() {
        var $target = $(this);
 
        // オリジナルの文章を取得する
        var html = $target.html();
 
        // 対象の要素を、高さにautoを指定し非表示で複製する
        var $clone = $target.clone();
        $clone
            .css({
                display: 'none',
                position : 'absolute',
                overflow : 'visible'
            })
            .width($target.width())
            .height('auto');
 
        // DOMを一旦追加
        $target.after($clone);
 
        // 指定した高さになるまで、1文字ずつ消去していく
        while((html.length > 0) && ($clone.height() > $target.height())) {
            html = html.substr(0, html.length - 1);
            $clone.html(html + '...');
        }
 
        // 文章を入れ替えて、複製した要素を削除する
        $target.html($clone.html());
        $clone.remove();
    });

//マウスオーバー編
    $('#snippet').mouseover(function(){
    　　$('#snippet').css('background-color', '#dcdcdc');
    });
    
    $('#snippet').mouseout(function(){
    　　$('#snippet').css('background-color', '');
    });
    
    $('#viewall').mouseover(function(){
     　  $('#snippet').css('background-color', '#dcdcdc');          
    　　$('#viewall').css('color', '#005580');
    　　$('#viewall').css('text-decoration', 'underline');
    });
    
    $('#viewall').mouseout(function(){
    　　$('#snippet').css('background-color', '');
    　　$('#viewall').css('color', '');
    　　$('#viewall').css('text-decoration', 'none');
    });
    
    $('#ui-about-text').mouseover(function(){
      $('#ui-about-text').css('text-decoration', 'underline');
    })
    
    $('#ui-about-text').mouseout(function(){
      $('#ui-about-text').css('text-decoration', 'none');
    })
    
    $('.submit_individual').mouseover(function(){
      $(this).css('text-decoration', 'underline');
    })
    
    $('.submit_individual').mouseout(function(){
      $(this).css('text-decoration', 'none');
    })                   
    
    
    
//モーダル編
    $('#snippet').click(function(){
      $('#allcontent').modal();
    })
    
    $('#viewall').click(function(){
      $('#allcontent').modal();
    })
    
    $('#about_open').click(function(){
      $('#modal_about').modal();
    })

   $('span.submit_individual').click(function(){
     id = $(this).closest("div.pin").attr("id")
     form_id = "form#individual_" + id
     //alert(form_id);
     $(form_id).submit(); 
   })

   $('[placeholder]').ahPlaceholder({
     placeholderColor : 'silver',
     placeholderAttr : 'placeholder',
     likeApple : true
   });

//Edit
  $("form.edit_form > div").css("display", "none");
  $("form.edit_form > div.ui-input-text").css("width", "64%");
  
  $(".edit_toggle").click(function(){
  	id = $(this).closest("div.pin").attr("id")
  	tag_parent = "#tags_" + id + " div"
  	//alert(tag_parent);
    $(tag_parent).toggle();
    $("form.edit_form > div.ui-btn").css({"width" : "33%","display":"inline-block"});
    return false;
  });

  $("form.edit_form").submit(function(){
  	id = $(this).closest("div.pin").attr("id")
  	tag_parent = "#tags_" + id + " div"
  	tag_view = "div#tags_view_" + id
  	
    $.ajax({
      url: "/tagedit",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
      	//alert(obj);
        $(tag_parent).toggle();       
        $(tag_view).html(obj);
      }
    });
    return false;
  });

  $(document).on('submit', "form.comment_form", function(){
  	id = $(this).closest("div.pin").attr("id")
  	comments_id = "div#comments_" + id;
  	form_id = "div#comment_form_" + id;
  	total_id = "div#comment_total_" + id;
    len = $(comments_id + " > div.comment").length;
    newlen = len + 1;
    msg = "Comment (" + newlen.toString() + ")"; 
    //alert(msg);
    
    comment = $(form_id).find("input[name='comment']").val();
    
    $.ajax({
      url: "/comment",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
      	var dataset = JSON.parse(obj);
        
        $(total_id).html(msg);

        $(comments_id).append([
  	      "<div class='comment'>",
  	      "<div class='commnt_text'>"+ dataset.comment + "</div>",
  	      "<div class='comment_time'>"+ dataset.time +"</div>",
  	      "</div>",
  	    ].join(""));
        
        $(form_id).find("input[name='comment']").val("");
        $('#columns').vgrid();  	    

      }
    });  
   
    return false;
  });
      
  $(document).on('submit', "form.ref_form", function(){
  	id = $(this).closest("div.pin").attr("id")
  	val_id = "#ref_val_" + id
  	count_id = "#ref_count_" + id
  	//alert(id);
    //alert($(this).serialize());
    $.ajax({
      url: "/refrection",
      type: 'POST',
      timeout: 10000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
        alert("Thank you!");
        $(val_id).val(obj)
        $(count_id).html(obj);     
      }
    });
    return false;
  });
  
  $(document).on('submit', "form.remove", function(){
  	id = $(this).closest("div.pin").attr("id")
  	div_id = "#" + id
    
    if(window.confirm('本当に削除しますか？')){
    
      $.ajax({
        url: "/remove",
        type: 'POST',
        timeout: 1000,
        data: $(this).serialize(),
        error: function(){alert('ERROR');},
        success: function(obj){
          alert("削除しました");
          $(div_id).remove();
          $('#columns').vgrid();      
        }
      });
      
    }
    return false;
  });

  $("form.rss_register").submit(function(){
    $.ajax({
      url: "/rss_register",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(str){
      	alert(str)
      	var dataset = JSON.parse(str);
        if(dataset.status == "error"){
          $(".settings-alert").show();
        }
        else{
          obj = "<li>" + dataset.feed_title + "</li>";
          $("ul.rss_list").append(obj);
        }
      }
    });
    return false;
  });
  
  
  //if (location.pathname == "/main") {
  //  timer = setTimeout(function(){ page_reload(); }, 60000);
  //}
  
  //function page_reload(){
  // 	location.reload();
  //}

  //$("#checkbox-a:checkbox").change(function() {
  //  var isChecked = $(this).attr("checked");
    
  //  if(isChecked == "checked"){
  //  	if (location.pathname == "/main") {
  //  	timer = setTimeout(function(){ page_reload(); }, 60000);
  //  	}
  //  } else {

  //  	clearTimeout(timer);
  //  }
    
  //})
  
  //$(".menu").click(function(){
  //  $("#toggle_menu").toggleClass("toggle_menu");
  //})
  
  $('form').submit(function() {
    //$(this).submit(function () {
    //    alert('フォームからのデータ送信は一度ずつ行なって下さい。');
    //    return false;
    //});
  
    $('input').keypress(function(ev) {
        if ((ev.which && ev.which === 13) || (ev.keyCode && ev.keyCode === 13)) {
                return false;
        } else {
                return true;
        }
        });
  });

   
   $('#exptab a').click(function (e) {
     e.preventDefault();
     $(this).tab('show');
   })
   
   $("form#recruit").submit(function(){
  		
      username = $("#recruit_username").val();
      email = $("#recruit_mail").val();

      if ((username == "") || (email == "")) {
       	alert('名前とメールアドレスは必ずご記入下さい。')
        return false;
      }
      else {
        return true;
      }

  })

  $(document).on('mouseenter', ".pin", function(){
        id = $(this).closest("div.pin").attr("id");
        val_id = "#cancel_" + id;   
        $(val_id).css('display', 'block');
    }
  );

  $(document).on('mouseleave', ".pin", function(){
        id = $(this).closest("div.pin").attr("id");
        val_id = "#cancel_" + id;   
        $(val_id).css('display', 'none');
    }
  );

});

   YUI().use('node-base', 'node-event-delegate', function (Y) {

        var menuButton = Y.one('.nav-menu-button'),
            nav        = Y.one('#nav');

        // Setting the active class name expands the menu vertically on small screens.
        menuButton.on('click', function (e) {
            nav.toggleClass('active');
        });

        // Your application code goes here...

    });