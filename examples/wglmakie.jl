using JSServe, Observables, WGLMakie, AbstractPlotting
using JSServe: @js_str, onjs, with_session, onload, Button, TextField, Slider, linkjs, serve_dom
using JSServe.DOM
using GeometryBasics
using MakieGallery, FileIO
set_theme!(resolution=(1200, 800))


function dom_handler(session, request)
    return hbox(
        vbox(
            scatter(1:4, color=1:4),
            scatter(1:4, color=rand(RGBAf0, 4)),
            scatter(1:4, color=rand(RGBf0, 4)),
            scatter(1:4, color=:red),
            scatter(1:4)
        ),
        vbox(
            scatter(1:4, marker='☼'),
            scatter(1:4, marker=['☼', '◒', '◑', '◐']),
            scatter(1:4, marker="☼◒◑◐"),
            # scatter(1:4, marker=rand(RGBf0, 10, 10), markersize=20px),
            scatter(1:4, markersize=20px),
            scatter(1:4, markersize=20, markerspace=Pixel),
            scatter(1:4, markersize=LinRange(20, 60, 4), markerspace=Pixel),
            scatter(1:4, marker='▲', markersize=0.3, rotations=LinRange(0, pi, 4)),
            )
        )
end

function dom_handler(session, request)
    return DOM.div(
        meshscatter(1:4, color=1:4),
        meshscatter(1:4, color=rand(RGBAf0, 4)),
        meshscatter(1:4, color=rand(RGBf0, 4)),
        meshscatter(1:4, color=:red),
        meshscatter(rand(Point3f0, 10), color=rand(RGBf0, 10)),
        meshscatter(rand(Point3f0, 10), marker=Pyramid(Point3f0(0), 1f0, 1f0)),
    )
end

function dom_handler(session, request)
    x = Point2f0[(1, 1), (2, 2), (3, 2), (4, 4)]
    points = connect(x, LineFace{Int}[(1, 2), (2, 3), (3, 4)])
    return DOM.div(
        linesegments(1:4),
        linesegments(1:4, linestyle=:dot),
        linesegments(1:4, linestyle=[0.0, 1.0, 2.0, 3.0, 4.0]),
        linesegments(1:4, color=1:4),
        linesegments(1:4, color=rand(RGBf0, 4), linewidth=4),
        linesegments(points)
    )
end

function dom_handler(session, request)
    data = AbstractPlotting.peaks()
    return hbox(vbox(
        surface(-10..10, -10..10, data, show_axis=false),
        surface(-10..10, -10..10, data, color=rand(size(data)...))),
        vbox(surface(-10..10, -10..10, data, color=rand(RGBf0, size(data)...)),
        surface(-10..10, -10..10, data, colormap=:magma, colorrange=(0.0, 2.0)),
    ))
end

function dom_handler(session, request)
    return vbox(
        image(rand(10, 10)),
        heatmap(rand(10, 10)),
    )
end

function dom_handler(session, request)
    return hbox(vbox(
        volume(rand(4, 4, 4), isovalue=0.5, isorange=0.01, algorithm=:iso),
        volume(rand(4, 4, 4), algorithm=:mip),
        volume(1..2, -1..1, -3..(-2), rand(4, 4, 4), algorithm=:absorption)),
        vbox(
        volume(rand(4, 4, 4), algorithm=Int32(5)),
        volume(rand(RGBAf0, 4, 4, 4), algorithm=:absorptionrgba),
        contour(rand(4, 4, 4)),
    ))
end

function dom_handler(session, request)
    cat = FileIO.load(MakieGallery.assetpath("cat.obj"))
    tex = FileIO.load(MakieGallery.assetpath("diffusemap.png"))
    return hbox(vbox(
        AbstractPlotting.mesh(Circle(Point2f0(0), 1f0)),
        AbstractPlotting.poly(decompose(Point2f0, Circle(Point2f0(0), 1f0)))), vbox(
        AbstractPlotting.mesh(cat, color=tex),
        AbstractPlotting.mesh([(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)]; color=[:red, :green, :blue], shading=false)
    ))
end

function n_times(f, n=10, interval=0.5)
    obs = Observable(f(1))
    @async for i in 2:n
        try
            obs[] = f(i)
            sleep(interval)
        catch e
            @warn "Error!" exception=CapturedException(e, Base.catch_backtrace())
        end
    end
    return obs
end

function dom_handler(session, request)
    s1 = annotations(n_times(i-> map(j-> ("$j", Point2f0(j*30, 0)), 1:i)), textsize=20,
                      limits=FRect2D(30, 0, 320, 50))
    s2 = scatter(n_times(i-> Point2f0.((1:i).*30, 0)), markersize=20px,
                  limits=FRect2D(30, 0, 320, 50))
    s3 = linesegments(n_times(i-> Point2f0.((2:2:2i).*30, 0)), limits=FRect2D(30, 0, 620, 50))
    s4 = lines(n_times(i-> Point2f0.((2:2:2i).*30, 0)), limits=FRect2D(30, 0, 620, 50))
    return hbox(s1, s2, s3, s4)
end
using AbstractPlotting.MakieLayout
function dom_handler(session, request)
    outer_padding = 30
    scene, layout = layoutscene(
        outer_padding, resolution = (1200, 700),
        backgroundcolor = RGBf0(0.98, 0.98, 0.98))
    ax1 = layout[1, 1] = LAxis(scene, title = "Sine")
    xx = 0:0.2:4pi
    line1 = lines!(ax1, sin.(xx), xx, color = :red)
    scat1 = scatter!(ax1, sin.(xx) .+ 0.2 .* randn.(), xx,
        color = (:red, 0.5), markersize = 15px, marker = '■')
    return scene
end

isdefined(Main, :app) && close(app)
app = JSServe.Application(dom_handler, "127.0.0.1", 8082)
