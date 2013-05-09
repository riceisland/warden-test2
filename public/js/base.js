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

//Edit

  $(".edit_toggle").click(function(){
  	id = $(this).closest("div.pin").attr("id")
  	tag_parent = "#tags_" + id + " div"
  	//alert(tag_parent);
    $(tag_parent).toggle();
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
      
  $("form.ref_form").submit(function(){
  	id = $(this).closest("div.pin").attr("id")
  	val_id = "#ref_val_" + id
  	count_id = "#ref_count_" + id
  	//alert(id);
    //alert($(this).serialize());
    $.ajax({
      url: "/refrection",
      type: 'POST',
      timeout: 1000,
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

  $("form.rss_register").submit(function(){
    $.ajax({
      url: "/rss_register",
      type: 'POST',
      timeout: 1000,
      data: $(this).serialize(),
      error: function(){alert('ERROR');},
      success: function(str){
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
  
  timer = setTimeout(function(){ page_reload(); }, 15000);
  
  function page_reload(){
  	location.reload();
  }

  $(".ui-checkbox :checkbox").change(function() {
    var isChecked = $(this).attr("checked");
    if(isChecked == "checked"){
    	timer = setTimeout(function(){ page_reload(); }, 4000);
    } else {
    	clearTimeout(timer);
    }
  })	 
      
  
});