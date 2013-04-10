var FollowBias = Backbone.View.extend({
  el:"background",
  events:{
  },
  
  initialize: function(){
    this.render_count = 0;
    this.topbar_down = false
    this.followbias_data = null;
    this.canvas = Raphael("background", "100%", "100%");
    this.render();
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
    }
  },

  fetch_followbias: function(){
    that = this;
    jQuery.get("/followbias/show/" + followbias_screen_name + ".json", function(data){
      if(data!=null){
        that.followbias_data = data;
        that.render();
      }else{
        window.setTimeout(function(){follow_bias.fetch_followbias()}, 15000)
      }
    }).error(function(){
      window.setTimeout(function(){follow_bias.fetch_followbias()}, 15000)
    });

  },

  generate_dimensions: function(){
    pie_rad_width = (window.innerWidth * 0.5) * 0.75
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

    men_percent_label = $("#men_percent")
    women_percent_label = $("#women_percent")

    men_percent_label.html(parseInt(men_percent * 100) + "%");
    $("#topbar_men").html(parseInt(men_percent * 100) + "%");
    women_percent_label.html(parseInt(women_percent * 100) + "%");
    $("#topbar_women").html(parseInt(women_percent * 100) + "%");

    men_percent_label.css("left", parseInt(d.cx - d.pie_radius/1.35) + "px")
    men_percent_label.css("font-size", parseInt((52/240)*d.pie_radius) + "px");
    men_percent_label.css("line-height", parseInt((52/240)*d.pie_radius) + "px");
    men_percent_label.css("top", parseInt(d.cy - men_percent_label.height()/3) + "px")

    women_percent_label.css("left", parseInt(d.cx + d.pie_radius/3.0) + "px")
    women_percent_label.css("font-size", parseInt((52/240)*d.pie_radius) + "px");
    women_percent_label.css("line-height", parseInt((52/240)*d.pie_radius) + "px");
    women_percent_label.css("top", parseInt(d.cy - women_percent_label.height()/3) + "px")
   
  },

  start_spinner: function(){
    if(this.spinner!=null){
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
    d3.select("#topbar").transition().ease("cubic").duration(200).style("margin-top", "0px");
  },
  
  raise_menu: function(){
    d3.select("#topbar").transition().ease("cubic").duration(200).style("margin-top", "-65px");
  },
 
  scroll: function(){
    background = $("#background")
    topbar = $("#topbar")
    if(this.topbar_down == false &&  $(window).scrollTop() > this.circle_center && parseInt(topbar.css("margin-top") ) < 0){
      this.topbar_down = true;
      this.drop_menu();
    }else if( this.topbar_down == true && $(window).scrollTop() < this.circle_center && parseInt(topbar.css("margin-top"))==0){
      this.raise_menu();
      this.topbar_down = false
    }
  }

});

var FBRouter = Backbone.Router.extend({
  routes:{
  }
});

router = new FBRouter();
follow_bias = new FollowBias();
Backbone.history.start();
