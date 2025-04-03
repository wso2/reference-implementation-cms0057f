# WSO2 Demo DTR Application

This project is a mock Document Template Retrieval (DTR) system built using React and TypeScript. It simulates key functionalities of modern DTR systems, such as managing prior authorization workflows and integrating with healthcare systems.

**_Note_**: This system is intended only for demo purposes and is not suitable for production use.

Feel free to explore and use it as a foundation for understanding healthcare application development concepts!

## Run in Dev mode

> Run the following command to install all the dependencies listed in the project's `package.json`

``` shell
npm install
```

> Run the following command to run in the development mode.

``` shell
npm run dev
```

> By default, it will run the application on port `5173`. <http://localhost:5173/>

## Production build

> Run the following command to install all the dependencies listed in the project's `package.json`

``` shell
npm install
```

> Run the following command to get the build artifacts.

``` shell
npm run build
```

> You will find the build artifacts in the `/dist` directory.
> The build script compiles your entire app into the build folder, ready to be statically served. However, actually serving it requires some kind of static file server. Run the following command to install it.

``` shell
npm install -g serve
```

Then execute the following command to run the build in the production mode.

``` shell
serve -s build
```

or if your build location is `/dist`

``` shell
serve -s dist
```

> By default, it will run the application on port `3000`. <http://localhost:3000>

## Key Features

- **Drug Prior Authorization Workflow**: The `DrugPriorAuth` page provides a user-friendly interface for managing prior authorization requests.
- **Responsive Design**: The application is designed to work seamlessly across different screen sizes.
- **Integration Ready**: Built with modern web technologies, making it easy to integrate with other healthcare systems.
