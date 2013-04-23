//grid system

//$(function(){

//$('#frame').sly({
//    scrollBar : "#scrollbar",
//    pagesBar: ".pages",
//	horizontal: 1,
//	itemNav: "basic",
//	dragHandle: 1,
//	dynamicHandle: 1,
//	dragging: 1,
//	scrollBy: 1,
//	speed: 300,
//	cycleBy: 'pages',
//	cycleInterval: 1000,
//	startPaused: 1
//});
  
//});

jQuery(function($) {
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
    
    
    
    $('.pin').click(function(){
      id = $(this).attr("id");
      //alert(id);
      $("form.individual", this).submit();
      
      
    })
    

});




//Edit

$(document).ready(function(){
  $(".twitter_fav_edit_toggle").click(function(){
    $(".twitter_fav_tags div").toggle();
  });
      
  $(".twitter_home_edit_toggle").click(function(){
    $(".twitter_home_tags div").toggle();
  });

  $(".tumblr_edit_toggle").click(function(){
    $(".tumblr_tags div").toggle();
  });

  $(".instagram_edit_toggle").click(function(){
    $(".instagram_tags div").toggle();
  }); 
  
  $(".evernote_edit_toggle").click(function(){
    $(".evernote_tags div").toggle();
  });
  
  $(".hatena_edit_toggle").click(function(){
    $(".hatena_tags div").toggle();
  });
   
});

$(document).ready(function(){

  $("form.twitter_fav_edit_form").submit(function(){
    $.ajax({
      url: "/tagedit",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
      	alert(obj);
        $(".twitter_fav_tags div").toggle();        
        $("div.twitter_fav_tags_view").html(obj);
      }
    });
    return false;
  });
    
  $("form.twitter_home_edit_form").submit(function(){
    $.ajax({
      url: "/tagedit",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
      	alert(obj);
        $(".twitter_home_tags div").toggle();        
        $("div.twitter_home_tags_view").html(obj);
      }
    });
    return false;
  });

  $("form.twitter_edit_form").submit(function(){
    $.ajax({
      url: "/tagedit",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
      	alert(obj);
        $(".twitter_tags div").toggle();        
        $("div.twitter_tags_view").html(obj);
      }
    });
    return false;
  });
  
  $("form.tumblr_edit_form").submit(function(){
    $.ajax({
      url: "/tagedit",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
        $(".tumblr_tags div").toggle();   
        $("div.tumblr_tags_view").html(obj); 
      }
    });
    return false;
  });
  
  $("form.instagram_edit_form").submit(function(){
    $.ajax({
      url: "/tagedit",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
        $(".instagram_tags div").toggle();   
        $("div.instagram_tags_view").html(obj);
      }
    });
    return false;
  });

  $("form.hatena_edit_form").submit(function(){
    $.ajax({
      url: "/tagedit",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
        $(".hatena_tags div").toggle();   
        $("div.hatena_tags_view").html(obj);  
      }
    });
    return false;
  });
  
  $("form.evernote_edit_form").submit(function(){
    $.ajax({
      url: "/tagedit",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
        $(".evernote_tags div").toggle();   
        $("div.evernote_tags_view").html(obj); 
      }
    });
    return false;
  });
  
  $("form.twitter_home_ref_form").submit(function(){
   //alert($(this).serialize());
    $.ajax({
      url: "/refrection",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
        alert("Thank you!");
        $("span.twitter_home_ref_count").html(obj);     
      }
    });
    return false;
  });

  $("form.twitter_fav_ref_form").submit(function(){
   //alert($(this).serialize());
    $.ajax({
      url: "/refrection",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
        alert("Thank you!");
        $("span.twitter_fav_ref_count").html(obj);     
      }
    });
    return false;
  });
  
  $("form.tumblr_ref_form").submit(function(){
   //alert($(this).serialize());
    $.ajax({
      url: "/refrection",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
        alert("Thank you!");
        $("span.tumblr_ref_count").html(obj);     
      }
    });
    return false;
  });  

  $("form.instagram_ref_form").submit(function(){
   //alert($(this).serialize());
    $.ajax({
      url: "/refrection",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
        alert("Thank you!");
        $("span.instagram_ref_count").html(obj);     
      }
    });
    return false;
  });  

  $("form.hatena_ref_form").submit(function(){
   //alert($(this).serialize());
    $.ajax({
      url: "/refrection",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
        alert("Thank you!");
        $("span.hatena_ref_count").html(obj);     
      }
    });
    return false;
  });  

  $("form.evernote_ref_form").submit(function(){
   //alert($(this).serialize());
    $.ajax({
      url: "/refrection",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(obj){
        alert("Thank you!");
        $("span.evernote_ref_count").html(obj);     
      }
    });
    return false;
  });  
});
