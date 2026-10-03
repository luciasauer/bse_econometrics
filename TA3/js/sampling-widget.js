// Sampling-distribution widget, adapted from Seeing Theory's "The Bootstrap"
// (Brown University, https://seeing-theory.brown.edu/frequentist-inference/
// index.html#section3). Same layout and controls as the original — pick a
// distribution, draw one sample, then repeat the experiment to build up the
// distribution of the sample mean — plus a mode switch:
//   * Monte Carlo: every replication draws a NEW sample from the population.
//   * Bootstrap:   every replication resamples (with replacement) from the
//                  one sample we observed (the original Seeing Theory version).
// Requires d3 v3 and jStat.
(function () {
  function init() {
    var root = document.getElementById("mc-widget");
    if (!root) return;

    var margin = {top: 40, right: 20, bottom: 30, left: 20},
        width = 700 - margin.left - margin.right,
        height = 470 - margin.top - margin.bottom;

    var svg = d3.select("#mc-svg").append("svg")
        .attr("width", "100%")
        .attr("height", "100%")
        .attr("viewBox", "0 0 " + (width + margin.left + margin.right) + " " + (height + margin.top + margin.bottom))
        .attr("preserveAspectRatio", "xMidYMid meet")
      .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var MAX_BALLS = 40;
    var dt = 400,
        n = 10,
        mode = "montecarlo",
        dist = null,
        param = [],
        y1 = height / 3,
        y2 = height / 2,
        y3 = 2 * height / 3,
        y4 = height,
        bins = 50,
        counts = [],
        samples = [];

    var x = d3.scale.linear().domain([-6, 6]).range([0, width]).clamp(true);
    var y = d3.scale.linear().domain([0, 1]).range([y1, 0]);
    var z = d3.scale.linear().domain([0, 1]).range([y4, y3 + 10]);

    svg.append("clipPath").attr("id", "mc-view")
      .append("rect").attr("x", 0).attr("y", 0).attr("width", width).attr("height", y1);

    function draw_bar(selection, dy, label, id) {
      var axis = selection.append("g").attr("class", "mc-axis");
      axis.append("line").attr("x1", 0).attr("x2", width).attr("y1", dy).attr("y2", dy);
      axis.append("text").attr("x", 0).attr("y", dy).attr("dy", "1.1em")
        .attr("id", id || null).text(label);
    }
    svg.call(draw_bar, y1, "distribution (population)");
    svg.call(draw_bar, y2, "sample");
    svg.call(draw_bar, y3, "new sample + average", "mc-row3-label");
    svg.call(draw_bar, y4, "count of sample means");

    var bars = svg.append("g").attr("class", "mc-histogram");
    function draw_histogram() {
      // bin width adapts to the expected spread sigma/sqrt(n), so the histogram
      // stays readable from n = 3 up to n = 1000
      var dom = x.domain(), w = dom[1] - dom[0],
          bw = Math.min(w / bins, Math.max(sigma / Math.sqrt(n) / 2, w / 150)),
          edges = d3.range(dom[0], dom[1] + bw, bw);
      var histogram = d3.layout.histogram().bins(edges).frequency(false);
      var data = histogram(counts);
      var ymax = d3.max(data.map(function (d) { return d.y; })) || 1;
      z.domain([0, ymax]);
      var bar = bars.selectAll("g").data(data);
      var barEnter = bar.enter().append("g").attr("class", "mc-bar");
      barEnter.append("rect");
      barEnter.append("text").attr("y", y4 - 15).attr("text-anchor", "middle");
      bar.select("rect")
          .attr("x", function (d) { return x(d.x) + 1; })
          .attr("width", function (d) { return Math.max(x(d.x + d.dx) - x(d.x) - 1, 0); })
        .transition().duration(250)
          .attr("y", function (d) { return z(d.y); })
          .attr("height", function (d) { return y4 - z(d.y); });
      bar.exit().remove();
      update_stats();
    }

    // Population mean / sd of the chosen distribution
    var mu = 0, sigma = 1;
    function pdf_data(start, end) {
      mu = jStat[dist].mean.apply(null, param);
      sigma = Math.sqrt(jStat[dist].variance.apply(null, param));
      return d3.range(start, end, 0.01).map(function (v) {
        return [v, jStat[dist].pdf.apply(null, [v].concat(param))];
      });
    }

    var mu_group = svg.append("g").attr("opacity", 0);
    mu_group.append("line").attr("class", "mc-mu").attr("y1", 10).attr("y2", height);
    mu_group.append("text").html("&mu;").attr("x", -4).attr("y", 4);

    function draw_sampling(datum, dur) {
      var ymax = d3.max(datum, function (d) { return isFinite(d[1]) ? d[1] : 0; });
      y.domain([0, Math.min(ymax * 1.1, 1.2)]);
      var line = d3.svg.line()
          .x(function (d) { return x(d[0]); })
          .y(function (d) { return y(d[1]); })
          .interpolate("basis");
      var area = d3.svg.area()
          .x(function (d) { return x(d[0]); })
          .y0(y1)
          .y1(function (d) { return y(d[1]); })
          .interpolate("basis");
      var pdf_area = svg.selectAll("path.mc-pdf-area").data([datum]);
      pdf_area.enter().append("path").attr("class", "mc-pdf-area").attr("clip-path", "url(#mc-view)");
      (dur ? pdf_area.transition().duration(dur) : pdf_area).attr("d", area);
      var pdf_line = svg.selectAll("path.mc-pdf").data([datum]);
      pdf_line.enter().append("path").attr("class", "mc-pdf").attr("clip-path", "url(#mc-view)");
      (dur ? pdf_line.transition().duration(dur) : pdf_line).attr("d", line);
      (dur ? mu_group.transition().duration(dur) : mu_group)
          .attr("transform", "translate(" + x(mu) + ")")
          .attr("opacity", 1);
    }

    function ball_radius() { return n <= 50 ? 5 : n <= 200 ? 3 : 1.8; }

    function draw_from_population(k) {
      var data = [];
      for (var i = 0; i < k; i++) data.push(jStat[dist].sample.apply(null, param));
      return data;
    }

    function sample(k) {
      if (dist == null) return [];
      var data = draw_from_population(k);
      var circle = svg.selectAll("circle.mc-sample").data(data);
      circle.enter().append("circle").attr("class", "mc-sample");
      circle.attr("r", ball_radius())
          .style("fill-opacity", n > 100 ? 0.45 : 1)
          .attr("cx", function (d) { return x(d); })
          .attr("cy", y1)
        .transition().duration(dt)
          .attr("cy", y2 - 5);
      circle.exit().remove();
      return data;
    }

    // One replication of the experiment: get n draws, average them, and drop
    // the average into the histogram.
    function replicate() {
      if (!samples.length) return;
      var data = [], startY;
      if (mode === "montecarlo") {
        data = draw_from_population(n);    // fresh sample from the population
        startY = y1;
      } else {
        for (var i = 0; i < n; i++) data.push(samples[Math.floor(n * Math.random())]);
        startY = y2;                        // resample from the observed sample
      }
      var mean = d3.mean(data);           // the average uses all n draws ...
      var shown = data.slice(0, MAX_BALLS); // ... but only a few of them are animated
      var group = svg.append("g").attr("class", "mc-ball-group");
      var balls = group.selectAll(".mc-resample").data(shown).enter().append("circle")
          .attr("class", "mc-resample")
          .attr("cx", function (d) { return x(d); })
          .attr("cy", startY)
          .attr("r", 5);
      // phase 1: the n draws fall to the "average" row, one after another
      balls.transition()
          .delay(function (d, k) { return k * dt / shown.length; })
          .duration(dt)
          .attr("cy", y3 - 3);
      // phase 2: they merge into their average
      setTimeout(function () {
        balls.transition().duration(dt)
            .attr("cx", x(mean))
            .style("fill", "#F28627");
      }, 2 * dt + 20);
      // phase 3: the average drops into the histogram
      setTimeout(function () {
        balls.transition().duration(dt)
            .attr("cy", y4 - 3)
            .attr("r", 3);
      }, 3 * dt + 40);
      setTimeout(function () {
        group.remove();
        counts.push(mean);
        draw_histogram();
      }, 4 * dt + 60);
    }

    function fmt(v) { return isFinite(v) ? v.toFixed(3) : "–"; }
    function update_stats() {
      var el = document.getElementById("mc-stats");
      if (!el) return;
      if (!counts.length || dist == null) { el.innerHTML = "&nbsp;"; return; }
      var m = d3.mean(counts),
          sd = counts.length > 1 ? d3.deviation(counts) : NaN;
      el.innerHTML =
        "replications <b>" + counts.length + "</b> &nbsp;·&nbsp; " +
        "mean of x̄ <b>" + fmt(m) + "</b> (μ = " + fmt(mu) + ") &nbsp;·&nbsp; " +
        "sd of x̄ <b>" + fmt(sd) + "</b> (σ/√n = " + fmt(sigma / Math.sqrt(n)) + ")";
    }

    function reset() {
      svg.selectAll("circle.mc-sample").remove();
      svg.selectAll("g.mc-ball-group").remove();
      svg.selectAll("g.mc-histogram g").remove();
      samples = [];
      counts = [];
      update_stats();
    }

    var view_parameters = {uniform: [-6, 6], normal: [-6, 6], studentt: [-6, 6],
                           chisquare: [-1, 11], exponential: [-1, 5], centralF: [-1, 5]};
    var initial_parameters = {uniform: [-5, 5], normal: [0, 1], studentt: [5],
                              chisquare: [5], exponential: [1], centralF: [5, 5]};

    function set_dist(value) {
      dist = value;
      param = initial_parameters[dist];
      var view = view_parameters[dist];
      x.domain(view);
      draw_sampling(pdf_data(view[0], view[1]), first ? 0 : 300);
      first = false;
      reset();
    }
    var first = true;

    function set_mode(value) {
      mode = value;
      var mc = mode === "montecarlo";
      document.getElementById("mc-row3-label").textContent =
        mc ? "new sample + average" : "resample + average";
      document.getElementById("mc-resample").textContent = mc ? "New sample" : "Resample";
      document.getElementById("mc-resample-100").textContent = mc ? "100 new samples" : "Resample 100 times";
      root.querySelectorAll(".mc-mode button").forEach(function (b) {
        b.classList.toggle("active", b.getAttribute("data-mode") === mode);
      });
      // keep the observed sample, start a fresh histogram
      svg.selectAll("g.mc-ball-group").remove();
      svg.selectAll("g.mc-histogram g").remove();
      counts = [];
      update_stats();
    }

    document.getElementById("mc-dist").addEventListener("change", function () { set_dist(this.value); });
    // the n slider moves over a list of values (data-values), e.g. 3, 5, ..., 1000
    var nSlider = document.getElementById("mc-n"),
        nValues = (nSlider.getAttribute("data-values") || "").split(",").map(Number).filter(Boolean);
    function read_n() { return nValues.length ? nValues[+nSlider.value] : +nSlider.value; }
    n = read_n();
    document.getElementById("mc-n-value").textContent = n;
    nSlider.addEventListener("input", function () {
      reset();
      n = read_n();
      document.getElementById("mc-n-value").textContent = n;
    });
    document.getElementById("mc-sample").addEventListener("click", function () {
      reset();
      samples = sample(n);
    });
    document.getElementById("mc-resample").addEventListener("click", replicate);
    document.getElementById("mc-resample-100").addEventListener("click", function () {
      var count = 0, interval = setInterval(function () {
        replicate();
        if (++count === 100) clearInterval(interval);
      }, dt / 100);
    });
    root.querySelectorAll(".mc-mode button").forEach(function (b) {
      b.addEventListener("click", function () { set_mode(b.getAttribute("data-mode")); });
    });

    // Reveal.js keystrokes (space, arrows) must not fire while using the controls
    root.addEventListener("keydown", function (e) { e.stopPropagation(); });

    set_dist(document.getElementById("mc-dist").value);
    set_mode("montecarlo");
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
