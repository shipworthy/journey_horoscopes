# Horoscopes Website – Journey Demo Application

## Summary

This simple Elixir Phoenix Liveview Horoscopes web application demonstrates the use of [Journey](https://hex.pm/packages/journey) for a simpler implementation.

You can see this application running at https://horoscopes.gojourney.dev

The application prompts the user for some inputs (name, birthday, pet preferences), validates the data (is the user's name "Bowser"?), computes the results as the data becomes available (zodiac sign, horoscope, "emailing" the horoscope to the user), and schedules recurring actions for the future (weekly horoscope "emails"). The session will also archive itself after two weeks of inactivity. The application also gives the user some UI toggles, to get some insights into what happens behind the scenes.  

The application uses Journey to define its flow – inputs and computations, and their dependencies. The graph is defined in [`./lib/demo/horoscope_graph.ex`](./lib/demo/horoscope_graph.ex).

The application also uses Journey for creating and executing an instance of that flow – from the moment the user engages with the page, at which point the id of the execution becomes part of the URL. 

The application also uses Journey for persisting user-provided and computed data points.

The application also uses Journey for persisting the state of UI toggles -- the user's selection is preserved across page reloads. 

The application also uses Journey to get some analytics about the state of the flow, and the visual representation of the graph itself.


## Running the app

To clone and run the application (assuming you already have elixir installed). The sequence gives you the option of running a Postgres DB in a container.

```
~/src $ git clone git@github.com:shipworthy/journey_horoscopes.git
~/src/journey_horoscopes $ mix deps.get
~/src/journey_horoscopes $ # if you want to create the db running in a container:
~/src/journey_horoscopes $ # make db-local-rebuild
~/src/journey_horoscopes $ make run-dev
...
[info] Access DemoWeb.Endpoint at http://localhost:4000
...
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser and play with the app running on your machine.


## Learn more

  * See this application running live: https://horoscopes.gojourney.dev
  * Journey documentation: https://hexdocs.pm/journey/Journey.html
  * Journey source code: https://github.com/shipworthy/journey
  * About Journey: https://gojourney.dev
  * Elixir: https://elixir-lang.org/
  * Phoenix Docs: https://hexdocs.pm/phoenix
