var FollowBias = Backbone.View.extend({
  el:"background",
  events:{
  },
  
  initialize: function(){
    this.render_count = 0;
    this.topbar_down = false
    this.canvas = Raphael("background", "100%", "100%");
    this.render();
    $(window).bind("resize.app", _.bind(this.render, this));
    $(window).bind("scroll", _.bind(this.scroll, this));
  },

  render: function(){
    if(this.render_count >=3){this.render_count=0;}

    men_percent = 0.35;
    women_percent = 0.45;
    bots_percent = 0.20;

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

    pie_rad_width = (window.innerWidth * 0.5) * 0.75
    pie_rad_height = (window.innerHeight * 0.5) * 0.75;
    if(pie_rad_width < pie_rad_height){
      pie_radius = pie_rad_width;
    }else{
      pie_radius = pie_rad_height;
    }

    cx = window.innerWidth/2.0
    cy = window.innerHeight/2.0;


/*		this.sector(this.canvas, cx, cy, 900, -10, 75, {fill: "rgb(211,113,136)", "stroke-width": 0});
		this.sector(this.canvas, cx, cy, 900, 74, 191, {fill: "rgb(105,127,158)", "stroke-width": 0});
		this.sector(this.canvas, cx, cy, 900, 190, 351, {fill: "rgb(91,91,91)", "stroke-width": 0});*/

		this.sector(this.canvas, cx, cy, 900, bots_end, women_start, {fill: "rgb(211,113,136)", "stroke-width": 0});
		this.sector(this.canvas, cx, cy, 900, men_end, men_start, {fill: "rgb(105,127,158)", "stroke-width": 0});
		this.sector(this.canvas, cx, cy, 900, bots_start, bots_end, {fill: "rgb(91,91,91)", "stroke-width": 0});

    glasses_radius = parseInt(pie_radius*2.5);
    glasses = $("#main_glasses");
    glasses.css("width", glasses_radius+ "px");
    glasses.css("left", cx - parseInt(glasses_radius/2.0) + "px");
    glasses.css("top", cy - parseInt(glasses.height()/2.0) + "px");

    this.circle_center = cy + glasses.height()/2.0;

    chapter_one = $("#chapter_one")
    chapter_one.css("margin-top", "-" + parseInt(pie_radius * 0.8) + "px");
    chapter_one.css("font-size", parseInt((18/240)*pie_radius) + "px");
    chapter_one.css("line-height", parseInt((18/240)*pie_radius) + "px");
    chapter_one.css("margin-bottom", parseInt((30/240)*pie_radius) + "px");

    $("#personal_see").css("font-size", parseInt((32/240)*pie_radius) + "px");
    $("#personal_see").css("line-height", parseInt((32/240)*pie_radius) + "px");

    circle = this.canvas.circle(cx, cy, pie_radius);
    circle.attr("fill", "#fff");
    circle.attr("fill-opacity", "0.20");
    circle.attr("stroke-width", "0");

    men_percent_label = $("#men_percent")
    women_percent_label = $("#women_percent")

    men_percent_label.html(parseInt(men_percent * 100) + "%");
    $("#topbar_men").html(parseInt(men_percent * 100) + "%");
    women_percent_label.html(parseInt(women_percent * 100) + "%");
    $("#topbar_women").html(parseInt(women_percent * 100) + "%");

    men_percent_label.css("left", parseInt(cx - pie_radius/1.35) + "px")
    men_percent_label.css("font-size", parseInt((52/240)*pie_radius) + "px");
    men_percent_label.css("line-height", parseInt((52/240)*pie_radius) + "px");
    men_percent_label.css("top", parseInt(cy - men_percent_label.height()/3) + "px")

    women_percent_label.css("left", parseInt(cx + pie_radius/3.0) + "px")
    women_percent_label.css("font-size", parseInt((52/240)*pie_radius) + "px");
    women_percent_label.css("line-height", parseInt((52/240)*pie_radius) + "px");
    women_percent_label.css("top", parseInt(cy - women_percent_label.height()/3) + "px")

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
