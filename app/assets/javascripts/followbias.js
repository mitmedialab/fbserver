//NOTE: THE FOLLOWING CODE IS DESIGNED TO PREVENT THIS PAGE FROM BEING PARSED
//]][][}}}{{}{{{}}{((}()



_.templateSettings = {
    interpolate: /\{\{\=(.+?)\}\}/g,
    evaluate: /\{\{(.+?)\}\}/g
};

var AccountCorrections = Backbone.View.extend({
  el:"#help",
  events:{
    "click .correction" : "correct_account",
    "click #start_corrections":"start_corrections"
  },
  
  initialize: function(){
    this.correct_account_template = _.template($("#correct_account_template").html());
    this.label_template = _.template("({{=page}}/{{=pages}})")
    this.corrections_paragraph = _.template($("#corrections_paragraph").html())
    this.corrections_progress_label = _.template($("#corrections_progress_label").html());
    this.corrections_active = false;
    this.fetching_corrections = false;
    $(".prev-page").hide();
  },

  next_page: function(){
    //$(".prev-page").show();
    if(this.fetching_corrections == false){
      this.fetching_corrections = true;
      this.fetch_corrections_page(this.current_page+1);
    }
  },

  correct_account: function(e){
    el = $(e.target);
    p = el.parent().parent();
    prev = p.find(".correction.selected");

    prev.removeClass("selected")

    el.toggleClass("selected");

    new_value = $(".label_row ." + el.attr('data-gender') + " .value").html()
    prev_value = $(".label_row ." + prev.attr('data-gender') + " .value").html()
    prev_var = prev.attr('data-gender')
    new_var = el.attr('data-gender')

		$(".label_row ." + new_var + " .value").html(parseInt(new_value)+1);
		$(".label_row ." + prev_var + " .value").html(parseInt(prev_value)-1);

    jQuery.post("/followbias/correct", {id: p.attr("data-id"), gender:el.attr("data-gender"), authenticity_token: AUTH_TOKEN}, function(data){

      console.log(data);
    });

    // now update the glasses
    if(["Male", "Female"].indexOf(new_var) >= 0){
      follow_bias.followbias_data[new_var.toLowerCase()] += 1;
    }
    if(["Male", "Female"].indexOf(prev_var) >= 0){
      follow_bias.followbias_data[prev_var.toLowerCase()] -= 1;
    }
    follow_bias.render_glasses();
  },

  fetch_gender_samples: function(){
    that = this;
    jQuery.get("/followbias/show_gender_samples/" + followbias_screen_name + ".json", function(data){
        new_div = $("<div id='accounts_page'>");
        _.each(data.friends, function(d){
          new_div.append(that.correct_account_template({account:d}));
        });
        $("#accounts_page").replaceWith(new_div);
        $("#accounts_page").children().addClass("samples")
    });
  },

  start_corrections: function(page){
    this.corrections_active = true;
    $("#start_corrections").remove();
    //$("#help").find("p").remove();
    //$("#scroll_improve").after(that.corrections_paragraph());
    this.fetch_corrections_page(0);
  },

  fetch_corrections_page: function(page){
    that = this;
    this.current_page = page; // could cause trouble. Should really be inside the jQuery
    jQuery.get("/followbias/show_page/" + followbias_screen_name + ".json?page=" + page, function(data){
      if(data!=null){
        that.pages = data;
        if(_.size(that.pages.friends) > 0){
          new_div = $("<div id='accounts_page'>");
          _.each(that.pages.friends, function(d){
            new_div.append(that.correct_account_template({account:d}));
          });
          $(".samples").remove();
          $("#accounts_page").append(new_div.children());
          account_corrections.fetching_corrections = false;
          visible_accounts = data.page_size * (that.current_page) + _.size(that.pages.friends);
          $("#correction_label").html(that.corrections_progress_label({visible: visible_accounts, total_following:follow_bias.followbias_data.total_following}));
          $("#correction_label").show();

        }else{
          console.log("End of corrections list");
        }
        
      }else{
      }
    });
  }
});

var FollowBias = Backbone.View.extend({
  el:"#background",
  events:{
/*    "click .correction": "correct_account"*/
  },
  
  initialize: function(){
    this.render_count = 0;
    this.topbar_down = false
    this.followbias_data = null;
    this.canvas = Raphael("background", "100%", "100%");
    this.survey_viewed = false;

    //this.render();
    $(window).bind("resize.app", _.bind(this.render, this));
    $(window).bind("scroll", _.bind(this.scroll, this));
  },

  render: function(){
    if(this.followbias_data == null){
      this.render_base_circle();
      this.start_spinner();
      this.fetch_followbias();
    }else{
      this.render_glasses();
      if(!this.survey_viewed){
        post_survey.start_survey_timer();
        this.survey_viewed = true;
      }
      $("#correction_label").css("top", ($(window).height() - 80) + "px");
      if(!account_corrections.corrections_active){
        account_corrections.fetch_gender_samples();
      }
    }
  },

  fetch_followbias: function(){
    that = this;
    jQuery.get("/followbias/show/" + followbias_screen_name + ".json", function(data){
      if(data!=null){
        follow_bias.followbias_data = data;
        follow_bias.render();
      }else{
        window.setTimeout(function(){follow_bias.fetch_followbias()}, 15000)
      }
    }).error(function(){
      window.setTimeout(function(){follow_bias.fetch_followbias()}, 15000)
    });

  },

  generate_dimensions: function(){
    pie_rad_width = (window.innerWidth * 0.5) * 0.55
    pie_rad_height = (window.innerHeight * 0.5) * 0.75;
    if(pie_rad_width < pie_rad_height){
      pie_radius = pie_rad_width;
    }else{
      pie_radius = pie_rad_height;
    }

    cx = window.innerWidth/2.0
    cy = window.innerHeight/2.0;
    glasses_radius = parseInt(pie_radius*2.5);

    return {
      cx:cx,
      cy:cy,
      pie_radius:pie_radius,
      glasses_radius:glasses_radius
    }
  },

  render_base_circle: function(){
    d = this.generate_dimensions();

    $(".appearonload").show();
    this.canvas.clear();

    glasses_radius = parseInt(d.pie_radius*2.5);


    glasses = $("#main_glasses");
    glasses.css("width", glasses_radius+ "px");
    glasses.css("left", d.cx - parseInt(glasses_radius/2.0) + "px");
    glasses.css("top", d.cy - parseInt(glasses.height()/2.0) + "px");

    left_eye = this.canvas.rect(cx - d.pie_radius/1.2, cy - glasses.height() /4.5 , glasses.width()/4,glasses.height()/2.0);
    left_eye.attr("fill", "rgb(105,127,158)");
    left_eye.attr("opacity", "0.7");
    left_eye.attr("stroke-width", "0");
    
    right_eye = this.canvas.rect(cx + d.pie_radius/4.0, cy - glasses.height() /4.5 , glasses.width()/4,glasses.height()/2.0);
    right_eye.attr("fill", "rgb(211,113,136)");
    right_eye.attr("opacity", "0.7");
    right_eye.attr("stroke-width", "0");


    this.circle_center = d.cy + glasses.height()/2.0;

    chapter_one = $("#chapter_one")
    chapter_one.css("margin-top", "-" + parseInt(d.pie_radius * 0.8) + "px");
    chapter_one.css("font-size", parseInt((18/240)*d.pie_radius) + "px");
    chapter_one.css("line-height", parseInt((18/240)*d.pie_radius) + "px");
    chapter_one.css("margin-bottom", parseInt((30/240)*d.pie_radius) + "px");

    $("#personal_see").css("font-size", parseInt((32/240)*d.pie_radius) + "px");
    $("#personal_see").css("line-height", parseInt((32/240)*d.pie_radius) + "px");

    $("#corner_nav a").css("font-size", parseInt((18/240)*d.pie_radius) + "px");
    $("#corner_nav a").css("line-height", parseInt((18/240)*d.pie_radius) + "px");
    $("#corner_nav a").css("margin-bottom",  parseInt((12/240)*d.pie_radius) + "px");
    $("#corner_nav").css("top", parseInt(cy + d.pie_radius/2.0));
    $("#corner_nav").css("left", parseInt(cx + d.pie_radius/1.1));
    $("#corner_nav").css("width", parseInt(parseInt((180/240)*d.pie_radius)));

    circle = this.canvas.circle(d.cx, d.cy, d.pie_radius);
    circle.attr("fill", "#fff");
    circle.attr("fill-opacity", "0.20");
    circle.attr("stroke-width", "0");
  },

  render_glasses: function(){
    if(this.render_count >=3){this.render_count=0;}
  
    men_percent = parseFloat(this.followbias_data.male) / parseFloat(this.followbias_data.total_following);
    women_percent = parseFloat(this.followbias_data.female) / parseFloat(this.followbias_data.total_following);
    bots_percent = 1.0 - (men_percent + women_percent);
 
    /*men_percent = 0.32;
    women_percent = 0.22;
    bots_percent = 0.45;*/

    bots_start = 180.0 + (180 - (bots_percent * 360.0) ) / 2.0;
    bots_end = bots_start + (bots_percent * 360.0);
    
    men_start = bots_start + 0.1;
    men_end = men_start - (men_percent * 360.0);
    women_start = men_end + 0.1;
    women_end = women_start + (women_percent * 360.0 );
    

    if(this.render_count > 0){
      this.render_count+=1;
      return null;
    }

    // Generate Dimensions
    d = this.generate_dimensions();

    this.render_base_circle();

		pink = this.sector(this.canvas, d.cx, d.cy, 900, bots_end, women_start, {fill: "rgb(211,113,136)", "stroke-width": 0});
    pink.toBack();
		blue = this.sector(this.canvas, d.cx, d.cy, 900, men_end, men_start, {fill: "rgb(105,127,158)", "stroke-width": 0});
    blue.toBack();
		grey = this.sector(this.canvas, d.cx, d.cy, 900, bots_start, bots_end, {fill: "rgb(91,91,91)", "stroke-width": 0});
    grey.toBack();

    men_percent_lens = $("#men_percent");
    women_percent_lens = $("#women_percent");
    bots_percent_lens = $("#bots_percent");

    men_percent_value = men_percent_lens.find(".value");;
    women_percent_value = women_percent_lens.find(".value");
    bots_percent_value = bots_percent_lens.find(".value");

    men_percent_value.html(Math.round(men_percent * 100) + "%");
    women_percent_value.html(Math.round(women_percent * 100) + "%");
    bots_percent_value.html(Math.round(bots_percent * 100) + "%");


    $("#topbar_men").html(Math.round(men_percent * 100) + "%");
    $("#topbar_women").html(Math.round(women_percent * 100) + "%");

    // it's important to set font-size and line-height before calculating left and top

    $("#background .value").css("font-size", parseInt((42/240)*d.pie_radius) + "px");
    $("#background .value").css("line-height", parseInt((42/240)*d.pie_radius) + "px");

    $(".value_label").css("font-size", parseInt((18/240)*d.pie_radius) + "px");
    $(".value_label").css("line-height", parseInt((18/240)*d.pie_radius) + "px");

    men_percent_lens.css("left", parseInt(d.cx - d.pie_radius/1.35) + "px");
    men_percent_lens.css("top", parseInt(d.cy - men_percent_lens.height()/2.8) + "px");

    women_percent_lens.css("left", parseInt(d.cx + d.pie_radius/3.0) + "px");
    women_percent_lens.css("top", parseInt(d.cy - women_percent_lens.height()/2.8) + "px");

    bots_percent_lens.css("left", parseInt(d.cx - bots_percent_lens.width()/2.0));
    bots_percent_lens.css("top", parseInt(d.cy + d.pie_radius/2.5) + "px");

    $(".gender_label.Male .value").html(this.followbias_data.male)
    $(".gender_label.Female .value").html(this.followbias_data.female)
    $(".gender_label.Unknown .value").html(this.followbias_data.unknown)
   
  },

  start_spinner: function(){
    if(this.spinner!=null){
//      this.spinner.stop();
      this.spinner.remove();
      this.spinner = null;
    }

    d = this.generate_dimensions();
    this.spinner = this.sector(this.canvas, d.cx, d.cy, 900, 0, 20, {fill: "#ffff00", "stroke-width": 0});
    this.spinner.attr("opacity", "0.5");
    this.spinner.toBack();
    a = Raphael.animation({transform: "r360" + "," + d.cx + "," + d.cy}, 10000);
    this.spinner.animate(a.repeat(Infinity));
  },
  stop_spinner: function(){
  },

  sector: function(paper, cx, cy, r, startAngle, endAngle, params) {
    var rad = Math.PI / 180
    var x1 = cx + r * Math.cos(-startAngle * rad),
        x2 = cx + r * Math.cos(-endAngle * rad),
        y1 = cy + r * Math.sin(-startAngle * rad),
        y2 = cy + r * Math.sin(-endAngle * rad);
    return paper.path(["M", cx, cy, "L", x1, y1, "A", r, r, 0, +(endAngle - startAngle > 180), 0, x2, y2, "z"]).attr(params);
  },
  
  drop_menu: function(){
    $("#topbar").show();
    d3.select("#topbar").transition().ease("cubic").duration(200).style("margin-top", "0px");
  },
  
  raise_menu: function(){
    d3.select("#topbar").transition().ease("cubic").duration(200).style("margin-top", "-65px");
    $("#topbar").hide();
  },
 
  scroll: function(){
    // handle topbar dropdown
    background = $("#background")
    topbar = $("#topbar")
    if(this.topbar_down == false &&  $(window).scrollTop() > this.circle_center && parseInt(topbar.css("margin-top") ) < 0){
      this.topbar_down = true;
      this.drop_menu();
    }else if( this.topbar_down == true && $(window).scrollTop() < this.circle_center && parseInt(topbar.css("margin-top"))==0){
      this.raise_menu();
      this.topbar_down = false
    }

    // handle account auto-scroll
    ap = $("#accounts_page");
    if( $(window).scrollTop() + $(window).height() + 200 >= ap.offset().top + ap.height()){
      if(account_corrections.corrections_active){
        account_corrections.next_page();
      }
    }
    
  }

});

var PostSurvey = Backbone.View.extend({
  el:"#post_survey",
  events:{
    "click .close" : "close_survey",
    "click .btn_close" : "close_survey",
    "click .btn_save" : "save_survey",
    "click #start_corrections":"start_corrections"
  },

  start_survey_timer: function(){
    window.setTimeout(function(){
      $("#post_survey").fadeIn();
    }, 30000);
  },

  initialize: function(){
    that = this;
    $("#final_survey").submit( function () {
      $.post( '/followbias/final_survey',
              $(this).serialize(),
              function(data){
                $(post_survey.el).find(".modal-footer").hide();
                $(post_survey.el).find(".modal-body").html($("#post_survey_thanks").html());
                $(post_survey.el).delay("5000").fadeOut();
              });
      return false;     
    });  
  },

  close_survey: function(e){
    $(this.el).hide();
    e.stopImmediatePropagation()
  },

  save_survey: function(){
    $("#final_survey").submit();
  },
});

var ShhView = Backbone.View.extend({
  el:"#shh",

  events:{
    "click .close": "close_shh",
    "click .btn_close": "close_shh"
  },

  initialize: function(){
  },

  close_shh: function(e){
    $(this.el).hide();
    follow_bias.render();
    e.stopImmediatePropagation()
  }
});

var FBRouter = Backbone.Router.extend({
  routes:{
    ":link":"scroll_to"
  },
  scroll_to: function(anchor){
    $('html, body').stop().animate({
        scrollTop: ($("#scroll_"+anchor).offset().top - 75)
    }, 900);
  }
});

router = new FBRouter();
account_corrections = new AccountCorrections();
follow_bias = new FollowBias();
post_survey = new PostSurvey();
shh_view = new ShhView();
Backbone.history.start();
