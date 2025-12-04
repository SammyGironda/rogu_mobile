# ROGU MOBILE

## Inicializar la APP

```bash
flutter doctor
```


### Descargar dependencias
```
flutter pub get
```
### Para ver los DISPOSITIVOS 

Nota: Asegúrate de que la Depuración USB esté activada en las opciones de desarrollador de tu dispositivo Android.


```bash
flutter devices
```
### El dispositivo que encuentres tiene id… para hacerlo CORRER 

Correr la Aplicación en el Dispositivo
Una vez que identifiques el ID de t

```bash
flutter run -d 23090RA98G 
```

## Si estas usando emulador
```bash

flutter emulators --launch "NOMBRE DEL EMULADOR"

flutter emulators

flutter run -d emulator-5554

flutter run -d 23129RA5FL

flutter run -d 23129RA5FL --dart-define=API_BASE_URL=http://"Dirección IPv4".:3000/api
```
