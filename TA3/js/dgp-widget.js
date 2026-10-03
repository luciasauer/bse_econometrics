// Monte Carlo lab for the OLS slope beta_2 in
//   y = 4 + 2 x2 + 2 x3 + eps,  eps ~ N(0, s_eps^2),
//   x2 ~ U[0, a],  x3 = x2 + v,  v ~ N(0, s_v^2).
// Every slider change re-runs R replications and redraws the density
// histogram of beta_2_hat. "Keep as reference" freezes the current
// histogram as an outline so the change in spread is easy to see.
// Requires d3 v3.
(function () {
  var BETA = [4, 2, 2], R = 2000, XMIN = -1, XMAX = 5, NBINS = 60;

  function randn() {
    var u = 0, v = 0;
    while (u === 0) u = Math.random();
    while (v === 0) v = Math.random();
    return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
  }

  // Solve the 3x3 system A b = c (Gaussian elimination) and return b[1]
  function slope(A, c) {
    var M = [A[0].concat(c[0]), A[1].concat(c[1]), A[2].concat(c[2])];
    for (var k = 0; k < 3; k++) {
      var p = k;
      for (var r = k + 1; r < 3; r++) if (Math.abs(M[r][k]) > Math.abs(M[p][k])) p = r;
      var tmp = M[k]; M[k] = M[p]; M[p] = tmp;
      for (var r2 = k + 1; r2 < 3; r2++) {
        var f = M[r2][k] / M[k][k];
        for (var c2 = k; c2 < 4; c2++) M[r2][c2] -= f * M[k][c2];
      }
    }
    var b = [0, 0, 0];
    for (var i = 2; i >= 0; i--) {
      var s = M[i][3];
      for (var j = i + 1; j < 3; j++) s -= M[i][j] * b[j];
      b[i] = s / M[i][i];
    }
    return b[1];
  }

  function simulate(n, sEps, sV, a) {
    var out = new Float64Array(R);
    for (var rep = 0; rep < R; rep++) {
      // accumulate X'X and X'y on the fly
      var s2 = 0, s3 = 0, s22 = 0, s23 = 0, s33 = 0, sy = 0, s2y = 0, s3y = 0;
      for (var i = 0; i < n; i++) {
        var x2 = a * Math.random(),
            x3 = x2 + sV * randn(),
            y = BETA[0] + BETA[1] * x2 + BETA[2] * x3 + sEps * randn();
        s2 += x2; s3 += x3; s22 += x2 * x2; s23 += x2 * x3; s33 += x3 * x3;
        sy += y; s2y += x2 * y; s3y += x3 * y;
      }
      out[rep] = slope([[n, s2, s3], [s2, s22, s23], [s3, s23, s33]], [sy, s2y, s3y]);
    }
    return out;
  }

  function init() {
    var root = document.getElementById("dgp-widget");
    if (!root) return;

    var margin = {top: 20, right: 20, bottom: 45, left: 50},
        width = 640 - margin.left - margin.right,
        height = 400 - margin.top - margin.bottom;

    var svg = d3.select("#dgp-svg").append("svg")
        .attr("width", "100%").attr("height", "100%")
        .attr("viewBox", "0 0 " + (width + margin.left + margin.right) + " " + (height + margin.top + margin.bottom))
        .attr("preserveAspectRatio", "xMidYMid meet")
      .append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var x = d3.scale.linear().domain([XMIN, XMAX]).range([0, width]);
    var y = d3.scale.linear().domain([0, 1]).range([height, 0]);
    var xAxis = d3.svg.axis().scale(x).orient("bottom").ticks(7);
    var yAxis = d3.svg.axis().scale(y).orient("left").ticks(5);

    svg.append("g").attr("class", "dgp-axis").attr("transform", "translate(0," + height + ")").call(xAxis);
    var gy = svg.append("g").attr("class", "dgp-axis").call(yAxis);
    svg.append("text").attr("class", "dgp-label").attr("x", width / 2).attr("y", height + 40)
      .attr("text-anchor", "middle").html("β&#770;&#8322;");
    svg.append("text").attr("class", "dgp-label").attr("transform", "rotate(-90)")
      .attr("x", -height / 2).attr("y", -38).attr("text-anchor", "middle").text("Density");

    var barsG = svg.append("g");
    var refPath = svg.append("path").attr("class", "dgp-ref");
    svg.append("line").attr("class", "dgp-true")
      .attr("x1", x(BETA[1])).attr("x2", x(BETA[1])).attr("y1", 0).attr("y2", height);
    svg.append("text").attr("class", "dgp-true-label").attr("x", x(BETA[1]) + 6).attr("y", 12)
      .html("true β&#8322; = 2");

    var binW = (XMAX - XMIN) / NBINS;
    function density(betas) {
      var c = new Array(NBINS).fill(0);
      for (var i = 0; i < betas.length; i++) {
        var k = Math.floor((betas[i] - XMIN) / binW);
        if (k >= 0 && k < NBINS) c[k]++;
      }
      return c.map(function (v, k) { return {x0: XMIN + k * binW, d: v / (betas.length * binW)}; });
    }

    var reference = null;
    function outline(h) {
      var pts = [[x(XMIN), y(0)]];
      h.forEach(function (b) {
        pts.push([x(b.x0), y(b.d)]);
        pts.push([x(b.x0 + binW), y(b.d)]);
      });
      pts.push([x(XMAX), y(0)]);
      return "M" + pts.join("L");
    }

    var current = null, currentStats = null;
    function controls() {
      return {
        n: +document.getElementById("dgp-n").value,
        sEps: +document.getElementById("dgp-seps").value,
        sV: +document.getElementById("dgp-sv").value,
        a: +document.getElementById("dgp-a").value
      };
    }

    function run() {
      var p = controls();
      ["n", "seps", "sv", "a"].forEach(function (k) {
        var key = {n: "n", seps: "sEps", sv: "sV", a: "a"}[k];
        document.getElementById("dgp-" + k + "-value").textContent = p[key];
      });
      var betas = simulate(p.n, p.sEps, p.sV, p.a);
      current = density(betas);
      var m = d3.mean(betas), sd = d3.deviation(betas);
      // Var(x2) = a^2/12 ; Var(x2 | x3) = Var(x2) s_v^2 / (Var(x2) + s_v^2)
      var vx2 = p.a * p.a / 12, vcond = vx2 * p.sV * p.sV / (vx2 + p.sV * p.sV);
      var seTheory = p.sEps / Math.sqrt(p.n * vcond);
      currentStats = {m: m, sd: sd};

      var ymax = d3.max(current, function (b) { return b.d; });
      if (reference) ymax = Math.max(ymax, d3.max(reference, function (b) { return b.d; }));
      y.domain([0, ymax * 1.08]);
      gy.call(yAxis);

      var bars = barsG.selectAll("rect").data(current);
      bars.enter().append("rect").attr("class", "dgp-bar");
      bars.attr("x", function (b) { return x(b.x0) + 0.5; })
          .attr("width", x(XMIN + binW) - x(XMIN) - 1)
          .attr("y", function (b) { return y(b.d); })
          .attr("height", function (b) { return height - y(b.d); });
      refPath.attr("d", reference ? outline(reference) : null);

      document.getElementById("dgp-stats").innerHTML =
        "mean(β&#770;&#8322;) <b>" + m.toFixed(3) + "</b> &nbsp;·&nbsp; " +
        "sd(β&#770;&#8322;) <b>" + sd.toFixed(3) + "</b> &nbsp;·&nbsp; " +
        "theory ≈ <b>" + seTheory.toFixed(3) + "</b>" +
        (reference ? " &nbsp;·&nbsp; <span class='dgp-ref-key'>reference sd " + reference.sd.toFixed(3) + "</span>" : "");
    }

    var pending = false;
    function schedule() {
      if (pending) return;
      pending = true;
      requestAnimationFrame(function () { pending = false; run(); });
    }

    ["dgp-n", "dgp-seps", "dgp-sv", "dgp-a"].forEach(function (id) {
      document.getElementById(id).addEventListener("input", schedule);
    });
    document.getElementById("dgp-rerun").addEventListener("click", run);
    document.getElementById("dgp-keep").addEventListener("click", function () {
      reference = current.slice();
      reference.sd = currentStats.sd;
      run();
    });
    document.getElementById("dgp-reset").addEventListener("click", function () {
      document.getElementById("dgp-n").value = 100;
      document.getElementById("dgp-seps").value = 32;
      document.getElementById("dgp-sv").value = 16;
      document.getElementById("dgp-a").value = 40;
      reference = null;
      run();
    });
    root.addEventListener("keydown", function (e) { e.stopPropagation(); });

    run();
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
