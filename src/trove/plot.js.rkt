#lang scribble/base
@(require "../../scribble-api.rkt" "../abbrevs.rkt")
@(require (only-in scribble/core delayed-block))

@(define (link T) (a-id T (xref "plot" T)))
@(define Color (a-id "Color" (xref "image-structs" "Color")))
@(define (t-field name ty) (a-field (tt name) ty))
@(define (t-record . rest)
   (apply a-record (map tt (filter (lambda (x) (not (string=? x "\n"))) rest))))

@(append-gen-docs
  `(module "plot"
    (path "src/arr/trove/plot.arr")

    (fun-spec (name "histogram") (arity 3))
    (fun-spec (name "pie-chart") (arity 2))
    (fun-spec (name "bar-chart") (arity 3))
    (fun-spec (name "grouped-bar-chart") (arity 3))

    (fun-spec (name "render-function") (arity 2))
    (fun-spec (name "render-scatter") (arity 2))
    (fun-spec (name "render-line") (arity 2))

    (fun-spec (name "render-multi-plot") (arity 3))

    (type-spec (name "PlotOptions"))
    (type-spec (name "PlotWindowOptions"))
    (data-spec
      (name "Plot")
      (variants ("line-plot" "scatter-plot" "function-plot")))
  ))

@docmodule["plot"]{
  The Pyret Plot library. It consists of plot, chart, and data visualization tools.
  All functions return the visualization as an image. Additionally, if @pyret{interact} is true,
  the visualization will appear on a dialog where users can interact with it.

  @itemlist[
    @item{To close the dialog, click the close button on the title bar or press @tt{esc}}
    @item{To save a snapshot of the visualization as a file, click the save button on the
          title bar and choose a location to save the image}
  ]

  Every function in this library is available on the @tt{plot} module object.
  For example, if you used @pyret{import plot as P}, you would write
  @pyret{P.render-function} to access @pyret{render-function} below. If you used
  @pyret{include}, then you can refer to identifiers without needing to prefix
  with @pyret{P.}.

  @;############################################################################
  @section{The Plot Type}

  (If you do not wish to customize the plotting, feel free to skip this section.
  There will be a link referring back to this section when necessary)

  @data-spec2["Plot" (list) (list
  @constructor-spec["Plot" "function-plot" `(("f" ("type" "normal") ("contract" ,(a-arrow N N)))
                                       ("options" ("type" "normal") ("contract" ,(link "PlotOptions"))))]
  @constructor-spec["Plot" "line-plot" `(("points" ("type" "normal") ("contract" ,TA))
                                         ("options" ("type" "normal") ("contract" ,(link "PlotOptions"))))]
  @constructor-spec["Plot" "scatter-plot" `(("points" ("type" "normal") ("contract" ,TA))
                                            ("options" ("type" "normal") ("contract" ,(link "PlotOptions"))))])]

  @nested[#:style 'inset]{

  @constructor-doc["Plot" "function-plot" (list `("f" ("type" "normal") ("contract" ,(a-arrow N N)))
                                          `("options" ("type" "normal") ("contract" ,(link "PlotOptions")))) (link "Plot")]{
    A graph of a function of one variable.

    @member-spec["f" #:type "normal" #:contract (a-arrow N N)]{
      A function to be graphed. The function doesn't need to be total:
      it can yield an error for some @pyret{x} (such as division by zero
      or resulting in an imaginary number).
    }
    @member-spec["options" #:type "normal" #:contract (link "PlotOptions")]
  }

  @constructor-doc["Plot" "line-plot" `(("points" ("type" "normal") ("contract" ,TA))
                                        ("options" ("type" "normal") ("contract" ,(link "PlotOptions")))) (link "Plot")]{
    A line plot or line chart, used to display "information as a series of data points called `markers'
    connected by straight line segments." (see @url["https://en.wikipedia.org/wiki/Line_chart"])

    @member-spec["points" #:type "normal" #:contract TA]{
      A table of two columns: @t-field["x" N] and @t-field["y" N]

      Because two consecutive data points will be connected by a line segment as they are,
      the rows of the table should have been sorted by the x-value.
    }
    @member-spec["options" #:type "normal" #:contract (link "PlotOptions")]
  }

  @constructor-doc["Plot" "scatter-plot" `(("points" ("type" "normal") ("contract" ,TA))
                                           ("options" ("type" "normal") ("contract" ,(link "PlotOptions")))) (link "Plot")]{
    A scatter plot or scatter chart, used "to display values for two variables for a set of data."
    (see @url["https://en.wikipedia.org/wiki/Scatter_plot"])

    @member-spec["points" #:type "normal" #:contract TA]{
      A table of two columns: @t-field["x" N] and @t-field["y" N].
      The order of rows in this table does not matter.
    }
    @member-spec["options" #:type "normal" #:contract (link "PlotOptions")]
  }
  }

  @examples{
    my-plot = function-plot(lam(x): num-sqrt(x + 1) end, plot-options)
  }

  @;############################################################################
  @section{Plot Functions}

  All plot functions will populate a dialog with controllers (textboxes and buttons)
  on the right which can be used to change the window boundaries and number of sample points.
  To zoom in at a specific region, you can click and drag on the plotting
  region. To zoom out, press @tt{shift} and click on the plotting region.
  To reset to the initial window boundaries, simply click on the plotting
  region.

  All changes by the controllers will not take an effect until the redraw button
  is pressed.

  The window boundaries could be any kind of real number (e.g., fraction, roughnum).
  However, when processing, it will be converted to a decimal number.
  For example, @pyret{1/3} will be converted to @pyret{0.3333...33} which
  is actually @pyret{3333...33/10000...00}. This incurs the numerical imprecision,
  but allows us to read the number easily.

  For function plot, we make a deliberate decision to show points (the tendency of the function)
  instead of connecting lines between them. This is to avoid the problem of inaccurate plotting
  causing from, for example, discontinuity of the function, or a function which oscillates infinitely.

  @function["render-multi-plot"
    #:contract (a-arrow S
                        (L-of (link "Plot"))
                        (link "PlotWindowOptions")
                        (L-of (link "Plot")))
    #:args '(("title" #f) ("lst" #f) ("options" #f))
    #:return (L-of (link "Plot"))
  ]{

  Display all @pyret-id{Plot}s in @pyret{lst} on a window with the configuration
  from @pyret{options} and with the title @pyret{title}.

  @examples{
  import image-structs as I
  p1 = function-plot(lam(x): x * x end, _.{color: I.red})
  p2 = line-plot(table: x :: Number, y :: Number
      row: 1, 1
      row: 2, 4
      row: 3, 9
      row: 4, 16
    end, _.{color: I.green})
  render-multi-plot(
    'quadratic function and a scatter plot',
    [list: p1, p2],
    _.{x-min: 0, x-max: 20, y-min: 0, y-max: 20})
  }

  The above example will plot a function @tt{y = x^2} using red color, and show
  a line chart connecting points in the table using green color. The left, right,
  top, bottom window boundary are 0, 20, 0, 20 respectively.
  }

  @function["render-function"
    #:contract (a-arrow S (a-arrow N N) (a-arrow N N))
    #:args '(("title" #f) ("f" #f))
    #:return (a-arrow N N)
  ]{
  A shorthand to construct an @link{function-plot} with default options and then
  display it. See @link{function-plot} for more information.

  @examples{
  NUM_E = ~2.71828
  render-function('converge to 1', lam(x): 1 - num-expt(NUM_E, 0 - x) end)
  }
  }

  @function["render-line"
    #:contract (a-arrow S TA TA)
    #:args '(("title" #f) ("tab" #f))
    #:return TA
  ]{
  A shorthand to construct a @link{line-plot} with default options and then
  display it. See @link{line-plot} for more information.

  @examples{
  render-line('My line', table: x, y
    row: 1, 2
    row: 2, 10
    row: 2.1, 3
    row: 2.4, 5
    row: 5, 1
  end)
  }
  }

  @function["render-scatter"
    #:contract (a-arrow S TA TA)
    #:args '(("title" #f) ("tab" #f))
    #:return TA
  ]{
  A shorthand to construct a @link{scatter-plot} with default options and then
  display it. See @link{scatter-plot} for more information.

  @examples{
  render-scatter('My scatter plot', table: x, y
    row: 1, 2
    row: 1, 3.1
    row: 4, 1
    row: 7, 3
    row: 4, 6
    row: 2, 5
  end)
  }
  }

  @;############################################################################
  @section{Visualization Functions}

  @function["histogram"
    #:contract (a-arrow S TA N TA)
    #:args '(("title" #f) ("tab" #f) ("n" #f))
    #:return TA
  ]{
  Display a histogram with @pyret{n} bins using data from @pyret{tab}
  which is a table with one column: @t-field["value" N].
  The range of the histogram is automatically inferred from the data.

  @examples{
  histogram('My histogram', table: value :: Number
    row: 1
    row: 1.2
    row: 2
    row: 3
    row: 10
    row: 3
    row: 6
    row: -1
  end, 4)
  }
  }

  @function["pie-chart"
    #:contract (a-arrow S TA TA)
    #:args '(("title" #f) ("tab" #f))
    #:return TA
  ]{
  Display a pie chart using data from @pyret{tab} which is a table with two columns:
  @t-field["label" S] and @t-field["value" N].

  @examples{
  pie-chart('My pie chart', table: label, value
    row: 'EU', 10.12
    row: 'Asia', 93.1
    row: 'America', 56.33
    row: 'Africa', 101.1
  end)
  }
  }

  @function["bar-chart"
    #:contract (a-arrow S TA S TA)
    #:args '(("title" #f) ("tab" #f) ("legend" #f))
    #:return TA
  ]{
  Display a bar chart using data from @pyret{tab} which is a table with two columns:
  @t-field["label" S] and @t-field["value" N]. @pyret{legend} indicates the legend
  of the data.

  @examples{
  bar-chart(
    'Frequency of letters',
    table: label, value
      row: 'A', 11
      row: 'B', 1
      row: 'C', 3
      row: 'D', 4
      row: 'E', 9
      row: 'F', 3
    end, 'Letter')
  }
  }

  @function["grouped-bar-chart"
    #:contract (a-arrow S TA (L-of S) TA)
    #:args '(("title" #f) ("tab" #f) ("legends" #f))
    #:return TA
  ]{
  Display a bar chart using data from @pyret{tab} which is a table with two columns:
  @t-field["label" S] and @t-field["values" (L-of N)]. @pyret{legends} indicates the legends
  of the data where the first value of the table column @pyret{values} corresponds to the first legend
  in @pyret{legends}, and so on.
  }

  @examples{
  grouped-bar-chart(
    'Populations of different states by age group',
    table: label, values
      row: 'CA', [list: 2704659, 4499890, 2159981, 3853788, 10604510, 8819342, 4114496]
      row: 'TX', [list: 2027307, 3277946, 1420518, 2454721, 7017731, 5656528, 2472223]
      row: 'NY', [list: 1208495, 2141490, 1058031, 1999120, 5355235, 5120254, 2607672]
      row: 'FL', [list: 1140516, 1938695, 925060, 1607297, 4782119, 4746856, 3187797]
      row: 'IL', [list: 894368, 1558919, 725973, 1311479, 3596343, 3239173, 1575308]
      row: 'PA', [list: 737462, 1345341, 679201, 1203944, 3157759, 3414001, 1910571]
    end, [list:
      'Under 5 Years',
      '5 to 13 Years',
      '14 to 17 Years',
      '18 to 24 Years',
      '25 to 44 Years',
      '45 to 64 Years',
      '65 Years and Over'])
  }

  @;############################################################################
  @section{The Options Types and Default Values}

  The PlotOptions and PlotWindowOptions type is actually a function type
  consuming a default config and produces a desired config.

  To use a default config, you could construct
  @pyret-block{lam(default-configs): default-configs end}
  which consumes a default config and merely returns it. We provide a value
  @pyret{default-options} and @pyret{default-window-options} which are the
  identity function above for convenience.

  A new Options can be constructed by the using @secref["s:extend-expr"] on
  the default config.

  @pyret-block{
    new-options = lam(default-configs): default-configs.{val1: ..., val2: ...} end
  }

  Combining the @secref["s:extend-expr"] with the @secref["s:curried-apply-expr"],
  the above can be rewritten as:

  @pyret-block{
    new-options = _.{val1: ..., val2: ...}
  }

  @type-spec["PlotOptions" '()]

  A config associated with @pyret-id{PlotOptions} consists of the following fields:
  @a-record[(t-field "color" Color)]

  The default config is @t-record{color: blue}

  @examples{
    import image-structs as I
    my-plot-options-1 = _.{color: I.red}
    my-plot-options-2 = default-options
  }

  @type-spec["PlotWindowOptions" '()]

  A config associated with @pyret-id{PlotWindowOptions} consists of the following fields:
  @a-record[(t-field "x-min" N)
            (t-field "x-max" N)
            (t-field "y-min" N)
            (t-field "y-max" N)
            (t-field "num-samples" N)
            (t-field "infer-bounds" B)]

  The default config is
  @t-record{x-min: -10
            x-max: 10
            y-min: -10
            y-max: 10
            num-samples: 1000
            infer-bounds: false}

  If @pyret{infer-bounds} is true,
  @pyret{x-min}, @pyret{x-max}, @pyret{y-min}, @pyret{y-max} will be inferred,
  and old values will be overwritten.

  @pyret{num-samples} is to control the number of sample points for
  @link{function-plot}s.
}
