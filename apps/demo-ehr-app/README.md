# WSO2 Demo EHR Application

This project is a mock Electronic Health Record (EHR) system built using React. It simulates key functionalities of modern EHR systems, such as managing patient records, scheduling appointments, and Coverage requirement discovery workflows.

**_Note_**: This system is intended only for demo purposes and is not suitable for production use.

Feel free to explore and use it as a foundation for understanding healthcare application development concepts!

# Run in Dev mode

> Run the following command to install all the dependencies listed in the project's `package.json`

```
npm install
```

> Run the following command to run in the development mode.

```
npm run dev
```

> By default it will run the application in port `5173`. http://localhost:5173/

# Production build

> Run the following command to install all the dependencies listed in the project's `package.json`

```
npm -i
```

> Run the following command to get the build artifacts.

```
npm run build
```

> You will find the build artifacts in `/dist` directory.

> The build script is building your entire app into the build folder, ready to be statically served. However actually serving it require some kind of static file server. Run the following command to install it.

```
npm install -g serve
```

Then execute the following command to run the build in the production mode.

```
serve -s build
```
or if your build location is `/dist`
```
server -s dist
```

> By default it will run the application in port `3000`. http://localhost:3000
