_ = require 'underscore'
qs = require 'querystring'
md = require 'marked'
mongoose = require 'mongoose'

module.exports = (app) ->

  app.helpers

    inspect: require('util').inspect
    qs: qs
    _: _

    markdown: (str) -> if str? then md.parse str, sanitize: true else ''
    markdown_ok: " <a href='http://daringfireball.net/projects/markdown/syntax'>Markdown</a> ok."

    relativeDate: require 'relative-date'

    pluralize: (n, counter) ->
      if n is 1
        "1 #{counter}"
      else
        "#{n} #{counter}s"

    avatar_url: (person, size = 30) ->
      if person.avatarURL
        person.avatarURL size*2
      else
        person.imageURL

    sponsors: require '../models/sponsor'

    locations: (people) ->
      _(people).chain()
        .compact()
        .pluck('location')
        .reduce((r, p) ->
          if p
            k = p.toLowerCase().replace(/\W.*/, '')
            r[k] = p if (!r[k] || r[k].length > p.length)
          r
        , {})
        .values()
        .value().join '; '

    address: (addr, host = 'maps.google.com') ->
      """
      <a href="http://#{host}/maps?q=#{addr}">
        <img class="map" src="http://maps.googleapis.com/maps/api/staticmap?center=#{addr}&zoom=15&size=226x140&sensor=false&markers=size:small|#{addr}"/>
      </a>
      """

    registration: app.enabled 'registration'
    preCoding: app.enabled 'pre-coding'
    coding: app.enabled 'coding'
    voting: app.enabled 'voting'

    Vote: mongoose.model 'Vote'
    stars: (count) ->
      stars = for i in [1..5]
        state = if i <= count then ' filled' else ''
        "<div class='star#{state}'></div>"
      "<div class='stars'>#{stars.join ''}</div>"

    favicon: (sponsor) -> favicons[sponsor]

  app.dynamicHelpers

    session: (req, res) -> req.session

    req: (req, res) -> req

    _csrf: (req, res) ->
      """<input type="hidden" name="_csrf" value="#{req.session._csrf}"/>"""

    title: (req, res) ->
      (title) ->
        req.pageTitle = title if title
        req.pageTitle

    admin: (req, res) -> req.user?.admin

    flash: (req, res) -> req.flash()

    canEdit: (req, res) ->
      (thing) ->
        if u = req.user
          u.admin or (u.id is thing.id)

    urlFor: (req, res) ->
      (options) ->
        q = _.clone req.query
        delete q._pjax
        _.extend q, options
        req.url.split('?')[0] + '?' + qs.stringify(q)

    # show the vote list if
    # 1. voting is finished, or
    # 2. voting is happening and a contestant or judge is logged in
    shouldShowVoteList: (req, res) ->
      not app.enabled('voting') or
        (req.user?.contestant or req.user?.judge)

favicons =
  ratchetio: '''
data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAghJREFUeNpiYMADEhKS+kvLKgLwqWHEJeGw/E6CxKd78d/ZBR785RdfuCVQ/gBRBkj0nRVQl+Dbz8POavDm608GdhZmBtYvrxmsflyd0JyXUoiungldQJCLLUGIk83g+vMPDF9+/Gb4/usPw68nNxkeXjheoOPg5UDQAD52Fv/7b78w/Ht264Ewyx+Gbx/fP+AWl2O4qRnC8O3pnX4FKXEBvAYwMzJ++PP3H8OfQ8sm/n5w+cLXp3cXfrl5ZsM/UUUGfo/0Cxxeuefd19xPgKlnQTfgz79/hV9+/hFgjWiQZ+TneiDFyCgvJcD14fPP3wsYhfgb3zx44fDk4AYFvLHA235iPg8HawI/JxsDPxcQc7J94OVgnch6+7g9y7nNG5csWTSBYDSqTrvUwMHGXC/Mzf5A8MODiYxPr8c/V3NTOB6nLog3DEAgPj6xQeDrs3pOhj8MTExMCgyfXuXzPD7XiK4Zqws8Vt1bz/L5pcOlF18/CPx8q8AtpcjAyifUeChKpQGbZRgueP/lZ+Hn2xcKf3z9IvCIW4HhxR82hg/ffpKelG3Lpzv8Z2SK5/z/w0Ht693AqVMmXcCmjgWXAaKW3vEvvvxQ+MfMxHDh7/8ABlIN+HJg2UbBn58MfgnLKwhxcBwgyQvC3afWSwpwB4jwclx48u6LgLQgtwIwLRhuCpDDcAVAgAEAp3PGptnqdxkAAAAASUVORK5CYII=
  '''
  teleportd: '''
data:image/x-icon;base64,AAABAAIAEBAAAAAAIABoBAAAJgAAACAgAAAAACAAqBAAAI4EAAAoAAAAEAAAACAAAAABACAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAA////Af///wH///8B////Af///xH19fVzsrKyvZubm9ubm5vbsrKyvfX19XP///8R////Af///wH///8B////Af///wH///8B////AePj41uAgIDtISEh/xEREf8RERH/ERER/xEREf8hISH/gICA7ePj41v///8B////Af///wH///8B////AcTExG8+Pj7/DAwMpRISEv8RERH/ERER/xEREf8RERH/ERER/xEREf8+Pj7/w8PDbf///wH///8B////AdPT0zs8PDz9GRkZ5wcHBwUcHBzhERER/xEREf8RERH/ERER/xEREf8RERH/ERER/z09Pf3T09M7////Af///wFmZmbDERER/xkZGZ////8BDw8PexAQEP8RERH/ERER/xEREf8RERH/ERER/w0NDf0QEBD/ZmZmw////wHMzMwlISEh/xAQEP8MDAxj////AQcHBwcPDw/DERER/xEREf8RERH/ERER/xEREf9HR0dZEBAQ0yEhIf/Nzc0lcXFxaREREf8RERG1////Af///wH///8BKioqJRUVFf8RERH/ERER/xEREf8RERH/cHBwQR0dHV0RERH/cHBwaT4+PnkRERH/MDAwY////wH///8B////LaOjo8kTExP/ERER/xEREf8RERH/ERER/25ubkEHBwcHFRUV8z09PXlKSkpzKysr/V5eXhv///896Ojof3R0dPUrKyv/Kysr/ysrK/8rKyv/Kysr/ygoKP84ODgd////ASkpKZ1HR0d1SEhIS0BAQMmlpaVtbGxs/0NDQ/83Nzf/Nzc3/zc3N/83Nzf/LCws8RoaGp0VFRVf////Af///wFTU1NrSkpKTxoaGgdPT0+ZWlpaoUZGRv9GRkb/RkZG/0ZGRv9GRkb/RkZG/01NTVP///8B////Af///wH///8BQ0NDNRoaGgn///8BPT09KzExMWlRUVH/VlZW/1ZWVv9WVlb/VlZW/1ZWVv+pqalV////Af///wH///8B////Af///wH///8B////Af///wH///8BNDQ0g05OTvllZWX/ZmZm/2ZmZv9mZmb/oqKi0////0P///9N9vb2W////wH///8B////Af///wH///8B////Af///wEuLi4hTk5OuXV1df91dXX/dXV1/3Z2dv+Wlpb/jY2N/1lZWav///8B////Af///wH///8B////Af///wH///8B////AYiIiH9ra2v/dXV1/3Z2dv9tbW3/WVlZ7zw8PH8zMzMJ////Af///wH///8B////Af///wH///8B////Af///wE2NjYDNjY2OTY2Nlk2NjZdNjY2PzY2Ngf///8B////Af///wH///8B////AQAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8oAAAAIAAAAEAAAAABACAAAAAAAIAQAAAAAAAAAAAAAAAAAAAAAAAA////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8T////W////5n///+j////zf///83///+j////mf///1v///8T////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///9D////u+7u7v+rq6v/cHBw/2hoaP9BQUH/QUFB/2hoaP9wcHD/q6ur/+7u7v////+7////Q////wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8r////t8HBwf9RUVH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/1FRUf/BwcH/////t////yv///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////SdbW1vVUVFT/EBAQ/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf9UVFT/1tbW9f///0n///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///228vLz/HBwc/w0NDf8ICAjlERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8cHBz/u7u7/f///23///8B////Af///wH///8B////Af///wH///8B////Af///wH///9PmZmZ/REREf8QEBD/ERERqwcHBwcYGBj9ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8UFBT/mZmZ/f///0v///8B////Af///wH///8B////Af///wH///8B////K7Ozs/UUFBT/ERER/xYWFvcHBwcT////ASkpKecRERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8UFBT/tra29f///yv///8B////Af///wH///8B////Af///wHKysrBHx8f/xEREf8RERH/OTk5p////wH///8BLS0tnxEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8fHx//ysrKwf///wH///8B////Af///wH///8B////P1dXV/8RERH/ERER/xEREf9ISEhd////Af///wEHBwcxDg4O/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf9XV1f/////P////wH///8B////Af///wG1tbXNERER/xEREf8RERH/ERER/xsbGyX///8B////Af///wETExO9EBAQ/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/DAwM/wkJCfcQEBD/ERER/xEREf+1tbXN////Af///wH///8B////H05OTv8RERH/ERER/xEREf8PDw/9BwcHA////wH///8B////AQcHBxsODg7pERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf9AQECxBwcHKxEREfERERH/ERER/05OTv////8f////Af///wG/v79zFBQU/xEREf8RERH/Dg4O/wkJCY////8B////Af///wH///8B////AQcHBy0SEhL5ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/2VlZYf///8BDQ0NXRAQEP8RERH/FBQU/8HBwXX///8B////AYSEhL0RERH/ERER/xEREf8UFBS7BwcHA////wH///8B////Af///wH///8B////AQ0NDXsQEBD/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/cHBwgf///wEHBwcDHR0d7REREf8RERH/gICAvf///wH///8BYmJi4xEREf8RERH/ERER/wcHBx////8B////Af///wH///8B////Af///wH///8BwcHBGSQkJP8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf9wcHCB////Af///wEgICCFERER/xEREf9jY2Pj////Af///wFFRUXxERER/xEREf8qKirn////Af///wH///8B////Af///wH///8B////Af///0nr6+vfGRkZ/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/3BwcIH///8B////AQcHBxkQEBD/ERER/0NDQ/H///8B////ATg4OPMRERH/ERER/zk5Oaf///8B////Af///wH///8B////Af///wn///+pvLy8/zMzM/8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/ERER/xEREf8RERH/bW1tf////wH///8B////ASkpKc8RERH/OTk59f///wH///8BRkZG7ykpKf8mJib/GBgYR////wH///8B////Af///wH///839vb213Jycv8pKSn/KSkp/ykpKf8pKSn/KSkp/ykpKf8pKSn/KSkp/ykpKf8pKSn/KSkp/ykpKf9ERERb////Af///wH///8BLi4uZykpKf9GRkbx////Af///wFPT0/fLi4u/zIyMvUSEhID////If///2f///+N////w9PT0/9QUFD/Li4u/y4uLv8uLi7/Li4u/y4uLv8uLi7/Li4u/y4uLv8uLi7/Li4u/y4uLv8tLS3/ISEh/RISEhv///8B////Af///wESEhITKioq/0lJSeP///8B////AU5OTrs0NDT/RkZGt////wHX19evrq6u/4+Pj/9kZGT/NDQ0/zQ0NP80NDT/NDQ0/zQ0NP80NDT/NDQ0/zQ0NP80NDT/NDQ0/y0tLf8eHh7/GRkZ/xUVFfkVFRV/////Af///wH///8B////Af///wFISEjnU1NTv////wH///8BPj4+bzs7O/9eXl5t////CYCAgP07Ozv/Ozs7/zs7O/87Ozv/Ozs7/zs7O/87Ozv/Ozs7/zs7O/87Ozv/Ozs7/zs7O/8yMjL/GRkZxRgYGE8YGBgl////Af///wH///8B////Af///wH///8B////AWBgYMc+Pj55////Af///wEaGhobOTk5/3R0dEnc3Nw7SUlJ/0JCQv9CQkL/QkJC/0JCQv9CQkL/QkJC/0JCQv9CQkL/QkJC/0JCQv9CQkL/QkJC/zs7O9EaGhoD////Af///wH///8B////Af///wH///8B////Af///wH///8BT09PlxoaGh////8B////Af///wE+Pj7NpqamUWpqaktKSkr/SkpK/0pKSv9KSkr/SkpK/0pKSv9KSkr/SkpK/0pKSv9KSkr/SkpK/0pKSv9KSkr/cHBwd////wH///8B////Af///wH///8B////Af///wH///8B////Af///wEmJiY7////Af///wH///8B////ASEhIUliYmJLISEhHzs7O/9SUlL/UlJS/1JSUv9SUlL/UlJS/1JSUv9SUlL/UlJS/1JSUv9SUlL/UlJS/1JSUv+np6eF////Af///wH///8B////Af///wH///8B////Af///wH///8B////ASEhIQP///8B////Af///wH///8B////ASQkJBv///8BJCQkh0dHR/9aWlr/Wlpa/1paWv9aWlr/Wlpa/1paWv9aWlr/Wlpa/1paWv9aWlr/Wlpa/6urq9H///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8BKioqpz8/P/9eXl7/Y2Nj/2NjY/9jY2P/Y2Nj/2NjY/9jY2P/Y2Nj/2NjY/9jY2P/kZGR/////1X///8B////Af///wH///8B////D////wP///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wEqKioDKioqYy0tLelJSUn/Z2dn/2pqav9qamr/ampq/2pqav9qamr/ampq/2pqav9qamr/zc3N/f///6X///9p////c////8H29vb/+Pj4Wf///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8BLi4uCS4uLns2Njb1Y2Nj/3Jycv9ycnL/cnJy/3Jycv9ycnL/cnJy/3Jycv90dHT/pKSk/8XFxf/AwMD/lZWV/29vb/94eHh9////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////ATAwMBtVVVXXeXl5/3l5ef95eXn/eXl5/3l5ef95eXn/eXl5/3l5ef95eXn/eXl5/3l5ef9nZ2f/PDw89TAwMDn///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Jc3Nzd9/f3//f39//39/f/9/f3//f39//39/f/9/f3//f39//39/f/9ra2v/RkZG/zMzM8EzMzMh////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wE1NTUlOjo60U9PT/9hYWH/ZGRk/3R0dP90dHT/aGho/2RkZP9TU1P/PT09/zU1Nb01NTU/////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wE2NjYNNjY2VTY2NpE2NjaZNjY2zTY2Ns02NjalNjY2mTY2NmE2NjYb////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH///8B////AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
  '''
  mongolab: '''
data:image/png;base64,AAABAAEAEBAAAAEAGABoAwAAFgAAACgAAAAQAAAAIAAAAAEAGAAAAAAAAAMAAAAAAAAAAAAAAAAAAAAAAACioZ4gHBYWEwsXFAwXEw0XEwwXEw0XEwwXEwwXEw0XEwwXEwwWEwsWEwsgHBajoZ4gHBYXEwwXFAwXFAwXEwwjHRVQQC41KRw2KRxQQC4kHhYXEw0XFAwWEwsXEwwgHBYWEwsXFAwWEwwXFAwjHhaxkmulfFOKWzCKWjCke1KxkGsjHhYWEwsWEwsWEwwWEwwXFAwWEwsWEwwXEwwoIxrEoXargVaRYDKQXzKrgVXEoXcoIxoXFAwXFAwXEwwXEwwXFAwWEwsXFAwXFAwqJBzYuI/Gm2uYZzeYZjfGmmvYt48qJRwXFAwWEwsXFAwXFAwXFAwXFAwXFAwXFAw1P0CHsbhxWUFigodihIpvVjx5pLcyPj8WEwsXFAwXFAwXFAwXFAwXEw0WEwwXEwwlQk9Vxfo+Z3czhq00jLc/W24pm/gbPE8XFAwXFAwWEwsXEw0XFAwWEwwWEwwXEwwkQk9gr9I9Rkc1pds1p988QUMziM4bPE4XFAwXFAwXFAwXEw0WEwsWEwsWEwsXFAwkQk9Uxfo+b4RQjqtRlLU/YnkomvgbPE8XFAwXFAwXEwwWEwwXFAwXFAwWEwsWEwskQk9fyPpGUlVyuNxzv+RESk0xnvgbPE8WEwsXFAwWEwwXEwwWEg0WEg0XEwwXEwwlQk960ftDR0Vuortupb9CQD9KqvkbPE8WEwsXFAwWEwsXFAwWEg0WEg0XEwwXEwwhOUR10PtsstVikKZikKdsqtFApPgbNkQXFAwWEwsXFAwWEwsXEwwXEwwXFAwXFAwZFxNZteJbw/ppyftqyfxet/kljOAZGBMXFAwWEwsXFAwXFAwXEwwWEwwXFAwWEwsXEwwmNzw3odkxtPk0qfgjh9cbMDwXEw0XFAwXFAwXEwwXEwwgHBYXEwwXFAwXFAwWEwsXFAwYFQ4dOUcdN0cYFA4WEwsXFAwWEwwXEwwWEwwgHRajoZ4gHBYXFAwXFAwXFAwWEwsXEwwXEw0XEw0XEwwWEwsXFAwXEwwXEwwgHBWioZ4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
  '''
  monitaur: '''
data:image/x-icon;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAADFBMVEUAAADW1tYAAAAAAABalUbBAAAABHRSTlP//wD//gy7CwAAAEhJREFUGJWFjwsOABAMQ7ve/9D2MWYRmoXsqQ6wCRcgojUVwA68YQKkewHoZku5EpIMDQdLKLiDPNRBZrADd9iMxxQ5n/757QDb9QGbAbzGqgAAAABJRU5ErkJggg==
  '''
  joyent: '''
data:image/x-icon;base64,AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAD///8A////AP///wD///8A2N/9Jnea/I08eP3PEmX9/xJl/f88eP3Pd5r8jdjf/Sb///8A////AP///wD///8A////AP///wD///8AkKr9cRhn/fcSZf3/EmX9/xJl/f8SZf3/EmX9/xJl/f8YZ/33kKr9cf///wD///8A////AP///wD4+P0GUYT8thJl/f8SZf3/EmX9/xJl/f8SZf3/EmX9/xJl/f8SZf3/EmX9/xJl/f9RhPy2+Pj9Bv///wD///8Acpf8kxJl/f8SZf3/EmX9/xJl/f8SZf3/EmX9/xJl/f8SZf3/EmX9/xJl/f8SZf3/EmX9/3SX/JH///8A0tr9KxNl/f0SZf3/EmX9/xJl/f8SZf3/EmX9////////////EmX9/xJl/f8SZf3/EmX9/xJl/f8TZf390tr9K3KX/JMSZf3/EmX9/xJl/f8SZf3/EmX9/xJl/f///////////xJl/f8SZf3/EmX9/xJl/f8SZf3/EmX9/3SX/JExcv3bEmX9/xJl/f8SZf3/EmX9/xJl/f8SZf3///////////8SZf3/EmX9/xJl/f8SZf3/EmX9/xJl/f82df3VF2f9+BJl/f8SZf3/EmX9////////////////////////////////////////////EmX9/xJl/f8SZf3/HGn98xdn/fgSZf3/EmX9/xJl/f///////////////////////////////////////////xJl/f8SZf3/EmX9/x5p/fAydP3ZEmX9/xJl/f8SZf3/EmX9/xJl/f8SZf3///////////8SZf3/EmX9/xJl/f8SZf3/EmX9/xJl/f82df3VdJf8kRJl/f8SZf3/EmX9/xJl/f8SZf3/EmX9////////////EmX9/xJl/f8SZf3/EmX9/xJl/f8SZf3/d5r8jdLa/SsTZf39EmX9/xJl/f8SZf3/EmX9/xJl/f///////////xJl/f8SZf3/EmX9/xJl/f8SZf3/E2X9/dTc/Sr///8AdJf8kRJl/f8SZf3/EmX9/xJl/f8SZf3/EmX9/xJl/f8SZf3/EmX9/xJl/f8SZf3/EmX9/3ea/I3///8A////APj4/QZRhPy2EmX9/xJl/f8SZf3/EmX9/xJl/f8SZf3/EmX9/xJl/f8SZf3/EmX9/1GE/Lb4+P0G////AP///wD///8A////AJCq/XEYZ/33EmX9/xJl/f8SZf3/EmX9/xJl/f8SZf3/GGf995Cq/XH///8A////AP///wD///8A////AP///wD///8A2N/9Jnea/I0+ef3NE2X9/RNl/f0+ef3Nd5r8jdjf/Sb///8A////AP///wD///8A+B8AAPAPAADAAwAAgAEAAIABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAQAAgAEAAMADAADwDwAA+B8AAA==
  '''
  nodejitsu: '''
data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAQAAAC1+jfqAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAPhJREFUGBmtwT0rBAAcwOH/ajCYlNVAXV6GMyILSeelUJfLqLsMTspLIg6d8pJSdKskXS6/2Qe4SUbpioWUb6Bu+BlMN9g8T8Q/op0bPvikTGc0opVpFnhDROSdLDO0xS9m+URERERE5ItMRNDDNyLihSMOey4iInX6glNERJz02oopERGRy+AGjx0y7a0bps24atmMgxZF7oNn7PfBNTfFnDmxYNaqAyK14BEn3DXtolhwT1x2ykNTItWgl9q1ebedN2/BfVecc8clr+SJjoighQzrnFVexuorbjlav3ulRJ5xmqJRonhkycRB/CXZ3F3sOkk2x7/6ATyh1BTVAG5VAAAAAElFTkSuQmCC
  '''
  bislr: '''
data:image/png;base64,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
  '''
  sequoia: '''
data:image/x-icon;base64,AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAAAABMLAAATCwAAAAAAAAAAAAAamAL/GpgC/xqYAv8amAL/GpgC/xqYAv8onhL/GpgC/xqYAv8amAL/GpgC/xqYAv8amAL/GpgC/xqYAv8amAL/GZkC/xmaAv8ZmQL/GZkC/xmaAv9Ts0H/t9+w/xiaAv8ZmgL/GZkC/xmZAv8ZmgH/GJkB/xmaAf8ZmgL/GZoC/xecAv8XmwL/F5wC/xebAv8YnAH/GJwC/8XmwP9StUH/F5wC/xibAv8XnAL/GJwB/xecAv8YnAL/GJwC/xecAf8VngH/Fp4C/xaeAf8WngL/Fp4C/xafAv+n2qD/xOe//xaeAv8WngH/Fp4B/xaeAv8WngL/Fp8C/xafAf8WnwH/FKEB/xShAf8ToQH/FKEC/yOnEf/T7c////////D57/9AszL/FKEC/xShAf8UoQH/FKIC/xShAf8ToQL/FKEB/xGkAf8SpAH/EqQC/y+vIf/S7s//////////////////8Pnv/8Pov/9cwVH/MK8h/xKkAf8SpAH/EaUC/xGkAv8PqAH/D6gB/x6tEf/S78////////////////////////////////////////////94znH/H60R/w+oAf8PqAL/DasB/w2rAf+G1YD//////////////////////////////////////////////////////6Tfn/8csBH/DasB/wuuAf8LrgH/4PXf///////////////////////g9d///////8Lrv/+F14D/////////////////o+Gf/wuvAf8JsgD/J7sh/+D13/+i4p/////////////g9d//8Prv///////B7L//CbIB/3XUcf/g9d////////////82wDH/BrUA/we1Af8mviD/kt6P////////////Jb4h/+D23///////0PHP/wa1Af8HtQD/BrUB/1TMUP+S3o//BrUA/wS4Af8EuAD/BLgB/9Dyz///////gtuA/wW4AP/A7b///////6Hkn/8FtwD/BbcA/wS4Af8EuAH/BbgA/wW4AP8DugD/ArsA/wO7AP9By0D/Mscw/wO7AP8CugD/sOmv//////9x2HD/AroA/wO6AP8DuwD/A7sB/wK6AP8DugD/Ab0A/wG9AP8BvQD/Ab0A/wG8AP8BvAH/Ab0A/zHJMP//////cdpx/wG8AP8BvAD/AbwA/wG8AP8BvAD/Ab0A/wC+AP8AvgD/AL4A/wC+AP8AvgD/AL4A/wC+AP8AvgD/gN+A/5/nn/8AvgD/AL4A/wC+AP8AvgD/AL4A/wC+AP8AvgD/AL4A/wC+AP8AvgD/AL4A/wC+AP8AvgD/AL4A/wC+AP8AvgD/AL4A/wC+AP8AvgD/AL4A/wC+AP8AvgD/AAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIA==
  '''
  nomic: '''
data:image/x-icon;base64,AAABAAEAEBAAAAAAAABoBQAAFgAAACgAAAAQAAAAIAAAAAEACAAAAAAAAAEAAAAAAAAAAAAAAAEAAAAAAAAlcYAADrzeABGy0QA2ODkAE6zJAA662wASsM4ANjw+AChpdQAPuNgADMLlAAnK7wA2ODgANzg4ADg4OAAdi6AANUBCAAbW/gAvUlkABtT7AC5WXgAsWmMAM0ZJABibtAAqXmgAB9L4ABSpxgAvVFsALFhgABuTqQAqYGoAELXVAA2/4gAsWmIAJm58AA+52gAtWmIAD7fXACdseQAkdoYAELfXADc5OgAxR0wACsnuADY3NwAfgpUANzc3AAzD5gAxSU4ALlNbAB2KnwAJy/AABtX9ADc5OQA0Q0YAMUtQABeguwAG1/8ALVliABmYsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOTk5OTk5OTk5OTk5OTk5OTk5OTk5OTkROTk5OTk5OTk5Mx8lJR8zOTkvODsCOTk5OQkONS4OLTkaNS4OLgA5OTQ5Bw4ODjo5IS4sDhYAATkROSYOLA42Cx4OLg4UOTk5OTkXLg4ODgYyDg0uDh85OTk5Iw4ODS4PAg4OLC4dOTk5ORMbDg4uEhkqDg0uGDkROTk5CA4NKS4TCA4NDAM5NDk5OQQQLgwOMDcuDgMuOTQ5ORE5KycODhwODg4uFTkROTk5OTk5BSQgIg4OMQo5OTk5OTk5NDk5OTkFKBM5ETk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  '''
  github: '''
data:image/x-icon;base64,AAABAAIAICAAAAEAIAAoEQAAJgAAABAQAAABACAAaAQAAE4RAAAoAAAAIAAAAEAAAAABACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////AP///wD///8A////AP///wD///8A////AP///wD///8A////ACgoKBMxMTFjMjIypDMzM9IyMjLzMzMz/zMzM/8yMjLzMzMz0jIyMqQxMTFjKCgoE////wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ADMzMy0yMjKnMzMz+jMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP6MjIypzMzMy3///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ACcnJw0zMzOWMjIy/jMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MjIy/jMzM5YnJycN////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wAvLy8rMjIy2zMzM/8zMzP/MzMz/zIyMsAzMzNaMzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8yMjJnMjIywDMzM/8zMzP/MzMz/zIyMtsvLy8r////AP///wD///8A////AP///wD///8A////AP///wD///8AMjIyODMzM/EzMzP/MzMz/zMzM9MzMzM8////AP///wAzMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zAwMBD///8AMzMzPDMzM9IzMzP/MzMz/zMzM/EyMjI4////AP///wD///8A////AP///wD///8A////AC8vLyszMzPxMzMz/zMzM/8zMzOXMzMzLTMzM4cyMjKjMjIyjzMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MDAwEP///wD///8AKysrBjMzM5YzMzP/MzMz/zMzM/EvLy8r////AP///wD///8A////AP///wAnJycNMjIy2zMzM/8zMzP/MjIyfzExMUMyMjL5MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zIyMv4zMzMF////AP///wD///8A////ADMzM34zMzP/MzMz/zIyMtsnJycN////AP///wD///8A////ADMzM5YzMzP/MzMz/zMzM5cAAAACMjIy1jMzM/cyMjKKMjIyYTIyMpAyMjL5MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz1P///wD///8A////AP///wD///8A////ADMzM5czMzP/MzMz/zMzM5b///8A////AP///wAzMzMtMjIy/jMzM/8zMzPSJCQkBzMzM2oyMjL9MTExRP///wD///8A////ADIyMoAyMjL+MzMz/zMzM/8zMzP/MzMz/zMzM/oyMjJN////AP///wD///8A////AP///wD///8AJCQkBzMzM9IzMzP/MjIy/jMzMy3///8A////ADIyMqczMzP/MzMz/zMzMzwyMjJsMjIy+TMzM2////8AMzMzFDIyMnAyMjK4MjIy6jMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zIyMuUyMjK4MjIycDMzMxT///8A////AP///wD///8AMzMzPDMzM/8zMzP/MjIyp////wAoKCgTMzMz+jMzM/8zMzPD////ADIyMjgzMzMj////ADIyMmwyMjL0MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MjIy9DExMW3///8A////AP///wD///8AMzMzwzMzM/8zMzP6KCgoEzExMWMzMzP/MzMz/zExMVj///8A////AP///wAxMTF8MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM37///8A////AP///wAxMTFYMzMz/zMzM/8xMTFjMjIypDMzM/8yMjL9MzMzD////wD///8AMTExKjMzM/wzMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MjIy/S8vLyv///8A////ADMzMw8yMjL9MzMz/zIyMqQzMzPSMzMz/zIyMsz///8A////AP///wAyMjKUMzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MjIymP///wD///8A////ADIyMswzMzP/MzMz0jIyMvMzMzP/MjIyqf///wD///8A////ADMzM9gzMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8yMjLa////AP///wD///8AMjIyqTMzM/8yMjLzMzMz/zMzM/8yMjKV////AP///wD///8AMzMz+zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zIyMv0AAAAE////AP///wAyMjKVMzMz/zMzM/8zMzP/MzMz/zIyMpD///8A////ADAwMBAzMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zAwMBD///8A////ADIyMpAzMzP/MzMz/zIyMvMzMzP/MjIyo////wD///8AAAAAAzIyMv4zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMzBf///wD///8AMjIyozMzM/8yMjLzMzMz0jMzM/8zMzPJ////AP///wD///8AMzMz0zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zIyMtX///8A////AP///wAzMzPJMzMz/zMzM9IyMjKkMzMz/zMzM/ozMzMK////AP///wAxMTF3MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMzeP///wD///8AMzMzCjMzM/ozMzP/MjIypDExMWMzMzP/MzMz/zMzM1X///8A////ADMzMwozMzPUMzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zIyMtUuLi4L////AP///wAzMzNVMzMz/zMzM/8xMTFjKCgoEzMzM/ozMzP/MzMzuv///wD///8A////ADMzM5czMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MjIymf///wD///8A////ADMzM7ozMzP/MzMz+igoKBP///8AMjIypzMzM/8zMzP/MzMzPP///wD///8AMjIyvDMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzO+////AP///wAzMzM8MzMz/zMzM/8yMjKn////AP///wAyMjIuMjIy/jMzM/8zMzPSJCQkB////wAyMjKyMzMz/zMzM/8zMzP/MjIy6TMzM7UzMzPoMzMz/zMzM/8zMzP/MzMz/zMzM+gzMzO1MjIy6TMzM/8zMzP/MzMz/zIyMrb///8AJCQkBzMzM9IzMzP/MjIy/jIyMi7///8A////AP///wAzMzOXMzMz/zMzM/8zMzOX////ADIyMoQzMzP/MzMz7TMzM4gtLS0R////AP///wAcHBwJMTExGi8vLxscHBwJ////AP///wAtLS0RMzMziDMzM+szMzP/MjIyhf///wAzMzOXMzMz/zMzM/8zMzOX////AP///wD///8A////ACcnJw0yMjLbMzMz/zMzM/8yMjKAMTExFTExMTQzMzMF////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AMzMzBTExMTQxMTEVMjIygDMzM/8zMzP/MjIy2ycnJw3///8A////AP///wD///8A////AC8vLyszMzPxMzMz/zMzM/8zMzOXJCQkB////wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AJCQkBzMzM5czMzP/MzMz/zMzM/EvLy8r////AP///wD///8A////AP///wD///8A////ADIyMjgzMzPxMzMz/zMzM/8zMzPSMzMzPP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ADMzMzwzMzPSMzMz/zMzM/8zMzPxMjIyOP///wD///8A////AP///wD///8A////AP///wD///8A////AC8vLysyMjLbMzMz/zMzM/8zMzP/MzMzujMzM1UzMzMK////AP///wD///8A////AP///wD///8AMzMzCjMzM1UzMzO6MzMz/zMzM/8zMzP/MjIy2y8vLyv///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ACcnJw0zMzOXMjIy/jMzM/8zMzP/MzMz/zMzM/ozMzPJMjIyozIyMpAyMjKQMjIyozMzM8kzMzP6MzMz/zMzM/8zMzP/MjIy/jMzM5cnJycN////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wAyMjIuMjIypzMzM/ozMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz+jIyMqcyMjIu////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AKCgoEzExMWMyMjKkMzMz0jIyMvMzMzP/MzMz/zIyMvMzMzPSMjIypDExMWMoKCgT////AP///wD///8A////AP///wD///8A////AP///wD///8A////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAoAAAAEAAAACAAAAABACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////AP///wD///8A////AC8vLzYyMjKaMjIy3zMzM/ozMzP6MjIy3zIyMpovLy82////AP///wD///8A////AP///wD///8AJCQkDjMzM6UzMzP/MjIy1TMzM/ozMzP/MzMz/zMzM/8yMjLWMzMz/zMzM6UkJCQO////AP///wD///8AJCQkDjMzM8kyMjLvMjIyV////wAzMzPwMzMz/zMzM/8zMzP/////ADIyMlcyMjLvMzMzySQkJA7///8A////ADMzM6UzMzPsMTExKv///wD///8AMzMzzTMzM/8zMzP/MjIy3////wD///8ALy8vKzMzM+0zMzOl////AC8vLzYzMzP/MjIyUf///wAvLy82MjIypDMzM+YzMzP/MzMz/zIyMuoyMjKpMzMzQf///wAyMjJRMzMz/y8vLzYyMjKaMzMzzf///wAyMjI9MzMz+jMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zIyMv0yMjJM////ADMzM80yMjKaMjIy3zExMXz///8AMjIytjMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMzyf///wAxMTF8MjIy3zMzM/ozMzNV////ADMzM+IzMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zIyMvT///8AMzMzVTMzM/ozMzP6MjIyV////wAzMzPZMzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzPs////ADIyMlczMzP6MjIy3zExMXz///8AMTExgTMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MjIyk////wAxMTF8MjIy3zIyMpozMzPO////AC8vLzYzMzP/MzMz/zMzM/8zMzP/MzMz/zMzM/8zMzP/MzMz/zIyMkf///8AMzMzzjIyMpovLy82MzMz/zMzM1AvLy8xMjIy/jIyMq0yMjJmMjIyiTIyMooxMTFoMjIyojMzM/sxMTFDMzMzUDMzM/8vLy82////ADMzM6UzMzPtMzMzKCQkJA7///8A////AP///wD///8A////AP///wArKysMMTExKjMzM+0zMzOl////AP///wAkJCQOMzMzyTMzM+0yMjJR////AP///wD///8A////AP///wD///8AMzMzUDMzM+0zMzPJJCQkDv///wD///8A////ACQkJA4zMzOlMzMz/zMzM84xMTF8MjIyVzIyMlcxMTF8MzMzzjMzM/8zMzOlJCQkDv///wD///8A////AP///wD///8A////AC8vLzYyMjKaMjIy3zMzM/ozMzP6MjIy3zIyMpovLy82////AP///wD///8A////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  '''
  nodetime: '''
data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAACvgAAAr4BJPgi0AAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAKBSURBVDiNfZNLaNRnFMV/55tvkplMCIKmoQjiwpj5z1ghnWChi5JUcVG68oHgzgduFBStL+hCqHZRpBuxXaSUCl1V6KroommSlRqYGCNJJj5QKD6xkladjGn8f9dFZiajiHd1F/ece+45XJkZjfVXFK0WbjtYQagASGLMjLGExT99Nj19t3FedQJJg1G0X+a+BUvzzlIF7Ju2TPp0oVicXySQNNSV+wPxRcP0I9CowXMRVoHrNuy6wx2MXYhj769uHB8ve4CFzXXwCI5dfZOTk427h6NopYXEB+bifhe01s3F3wFHNZDNrnYkrlVlf//P9NSRrWbxu0+AoSh/F1gp6SSV8ilfNSwtdPnJ9OR7wYNdXcvlfDu4zYE4o3R6pwcrgDB7tWNZLtczmM13SwrlTOrXL4vF2TcsTCT3Ezhn9v+InL+H+M1Xo/q7rbX1zrPyy/8kS4PRWq50Aodr4IudnW0p37RbXuv6Jm7cH8zlSzI+daAWM64+f/o00RifSZnG7c2+aQ/YUO/ExO2F+BgAEh7CBaErcSqVcY0Is7ZaO9rTkxQ6INmW+jlmj4MY9TL3uyn0OhLjwCEpXLKgDuCX4Sh/BmPEZBuQ7vdOTV1ZVMjHDhW9Yf2gJWAo1fRz79jYvwDDufyfZuxD7ANBsCM18HkpsTSb+ygQjjtE/RkqL16EWh/QgzcScNyq9e1d0TFkP6wvlW76INsmcwWZ3Uk2Ny8BngEoMIcWCUKsOYChfP4TQz2fl6Y2Vb2wuqz2bO5rkzLlltSJ1MxM0jenvwohJB085MOOszx8vNcc832l0o9UgXr7nQfWrFnhY9sazGaRe+XMKoAh+Zj48vpS6Wbj/GtmLBD7nVj69wAAAABJRU5ErkJggg==
  '''
  dropbox: '''
data:image/x-icon;base64,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Qf/qrmD/8tOp//jkyP/yt2j/7aJA/+iVLP/vqlH/6bp8/651KvGLQQBYmlYAAJ9dB8HZmET//82F//m8bf/pnTv/7K5e/+izbP/y2bf/76JD/+VzAP/qmTP/56NM//nOlv//68f/2bOB/59fEMSdWgaz4KBJ///Siv/ytWX/6Jcv/+mkS//wzZz//Pn2//zs1v/wq1j/5ooV/+abOf/xxoz///DR/+G+i/+dXA62mVcAAIxJAHHDiTnx8rBZ/++qUv/33rz//vz5//vy4//86tP///v1//fbt//tsWT/8sOG/8STUvONRAB1mVQAAKBeAACXVAAAfzgAntGUQ///9t7///z1//vv4P/78OD/++XI//vnz//////////+/9KdVv+AMgCillEAAKBfAACWVAAAkU4AntWYRP/8yYT/8cOF//bbt//89On//fXp//3u2//879//9tWo//G/fP/81qP/1qps/5FKAKGWUQAAnlsI3PCwWP//0IT/8Lx4//DCg//uw4j/89ex////+f//7Mr/87pt/+6uWP/wvnv/8MeR///y0v/w1Kb/nl0R3p5cBZfFhDH/9rtr///Qjv/ww4b/9dKi///nxP/AkFD/v3UV//+/Zv/2wXj/8MCA///fsP/216n/xZdc/55dC5idWwAAjEkAKptYBcDVm1D//92n///lu/+7hkD/iT4ARIlEAEK7eyf//8+J///bov/Vpmf/m1kHw4xDACydWwAAnlwAAKBeAACXVAAAjEYAX7qBMf+2fCv/jkYAP55cAACeXAAAjkoAO7Z5JP+8fy3/jEUAYpdSAACgXgAAnlwAAJ5cAACeXAAAoF4AAJlWAACRTABnk04AcZxYAACfXgAAn10AAJxZAACUUABvkk0AaZlWAACgXgAAnlwAAJ5cAAD+fwAA/D8AAPgfAADgBwAA4AcAAIABAAAAAAAAAAAAAIABAADAAwAAgAEAAAAAAAAAAAAAwYMAAOPHAADzzwAA
  '''
  coderwall: '''
data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAPdJREFUeNpitOs9w0AJYILSlkA8B4gDkeT4gbgFivmRxAOhakF6GFigknuBmBOIk4HYCoiPA/EEIE6AapIG4kQgNgPidVCxKCCWhLmAGckGNijNiSTGiUUMrIdZ3j3tJ5C+B8QKQDwTiBdBFZwCYjUgvg3EBUD8EYgfAvF/IOYD4gogPsNIrUDEBkSBuAuKRZHEQX5fCsQ2sEDEBbqQAlEUGoiWUM0gEALEYkwMFAJ8LqgE4ndQdjeUPg51iSsQzwUFLE0DEReoBuKT0MAk2QB7aNI2g6YXIVIN+I7E/gXCpBoASp1B0AB0BuIvLGSEwXooBgOAAAMA9+4sb+4z3PsAAAAASUVORK5CYII=
  '''
  nodeconf: '''
data:image/x-icon;base64,AAABAAEAEBAAAAAAAABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAA4TvkAOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75SDhO+WA4TvkAOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75SDhO+fk4Tvn/OE75YDhO+QA4TvkAOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75SDhO+fk4Tvn/OE75/zhO+f84TvlgOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75SDhO+fk4Tvn/OE75/zhO+f84Tvn/OE75/zhO+WA4TvkAOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75SDhO+fk4Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75YDhO+QA4TvkAOE75ADhO+QA4TvkAOE75SDhO+fk4Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84TvljOE75ADhO+QA4TvkAOE75SDhO+fk4Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+WM4TvkAOE75SDhO+fk4Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75YzhO+Zk4Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+bc4TvkAOE75nzhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+bc4TvkGOE75ADhO+QA4TvmfOE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+bc4TvkGOE75ADhO+QA4TvkAOE75ADhO+Z84Tvn/OE75/zhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+bc4TvkGOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75nzhO+f84Tvn/OE75/zhO+f84Tvn/OE75/zhO+bc4TvkGOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75ADhO+QA4TvmcOE75/zhO+f84Tvn/OE75/zhO+bc4TvkGOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75ADhO+Zw4Tvn/OE75/zhO+bc4TvkGOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75ADhO+QA4TvkAOE75nDhO+bc4TvkGOE75ADhO+QA4TvkAOE75ADhO+QA4TvkA//8AAP5/AAD8PwAA+B8AAPAPAADgBwAAwAMAAIABAAAAAAAAgAEAAMADAADgBwAA8A8AAPgfAAD8PwAA/n8AAA==
  '''
  voxer: '''
data:image/x-icon;base64,AAABAAEAEBAAAAEACABoBQAAFgAAACgAAAAQAAAAIAAAAAEACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAW/QAAF30AABf9AAAYfQAAGP0AABk9AAAZfQAAGX1AABm9AAAZ/UAAmj1AARp9QAHa/UACGv1AAhs9QAKbfUADG71AA9w9QATc/YAFXT2ABZ09gAXdfYAGHX2ABl29gAfefYAJHz2ACd+9wAtgvcAL4P3ADGE9gAzhfcAR5H3AFib+ABjovkAaqb5AGum+QBuqfkAcqv5AH6y+gCBtPoAg7X6AIS1+gCUv/oAq837AK3O/ACuzvwAr8/8ALDQ/AC31PwAu9b8ALzX/AC92PwAwNn8AMTc/ADG3fwAzuL9AM/i/QDX5/0A2ej9ANvq/QDc6v0A3ev9AN/r/QDf7P0A5/H9AOry/gDr8/4A7PT+AO30/gDu9f4A8fb+APH3/gD5+/4A/P3+AP7+/gD+/v8A///+AP7//wD///8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJgYGN05OTk5OTk5OTk45IgsIBjdOTk5OTk5OTk5OOgwJCQY3Sk5OQT8+Qk5OTDoOCQkGN04tKTI8PTMoLUs6DgkJBjdJRU5OTExOTkRIOg4JCQc4RB9OTk5OTk4gQToOCQkFMUglTk5OTk5OJEc6DgkJCBRFTk5OTk5OTk5OOg4JCQobAxweHh4eHhpDTjoOCQgeOwAEBAQEBgYBQE46DggMK04hIyMjIh0GAjVGNAsFKk5KTk5OTk5ODwgQGBEIBC9OTk5OTk5OThYICQkJCQQuTk5OTk5OTk4VCAkJCQkTLE5NTk5OTkpOFAYICAgNNidOTk5OTk5OQRIXFxcZMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  '''
