# Newsly

Lector móvil de noticias de The Guardian en Flutter. La interfaz editorial en español se adapta a teléfonos y tabletas. Los artículos conservan su idioma original.

## Cómo ejecutar

Requiere Flutter 3.44 con Dart 3.12 o una versión compatible. Crea `config/.env` a partir de [la plantilla](config/.env.example) y completa `GUARDIAN_API_KEY` con tu clave de [The Guardian Open Platform](https://open-platform.theguardian.com/access/).

```sh
flutter pub get
flutter run
```

Ejecuta la app en un teléfono, emulador de Android o simulador de iOS. El riel lateral aparece a partir de 760 píxeles lógicos de ancho. En pantallas más estrechas, la navegación se ubica al pie.

`config/.env` está excluido de Git. El archivo se incluye dentro de las compilaciones locales que lo tienen presente. Si distribuyes un binario, usa un servicio intermedio para mantener la clave en el servidor. Las compilaciones sin clave muestran un estado de configuración.

## Funcionalidades

- **Inicio** muestra una noticia destacada y las publicaciones recientes de la sección seleccionada.
- **Búsqueda** consulta Guardian al dejar de escribir o pulsar Intro. Cada sección conserva su navegación al cambiar de pestaña.
- **Detalle** muestra el texto, la autoría, la fecha, un tiempo de lectura estimado y el enlace a la publicación original.
- **Favoritos** guarda el contenido de los artículos en Hive. Al guardar desde una lista, Newsly obtiene el detalle antes de escribirlo. Luego puedes leer el texto y quitar el favorito sin conexión, incluso tras reiniciar la app. Las imágenes dependen de la caché disponible.
- **Actualización** al deslizar hacia abajo en Inicio, Buscar y Favoritos. Si falla una actualización, las noticias de la pantalla siguen visibles mientras puedes reintentar.

## Arquitectura

| Área | Responsabilidad |
| --- | --- |
| `lib/core` | Service locator con GetIt, cliente e interceptor de Dio, fallos, excepciones, `BaseUseCase` y utilidades. |
| `lib/features/news/domain` | Entidades, contrato de repositorio y casos de uso con `Either<Failure, T>` de dartz. |
| `lib/features/news/data` | Fuentes Guardian y Hive, modelos de persistencia y repositorio. |
| `lib/features/news/presentation` | BLoCs con eventos y estados por pantalla, páginas, widgets y rutas nombradas de go_router. |

El cliente espacia las solicitudes a The Guardian. La interfaz distingue pérdida de conexión, tiempo de espera, acceso rechazado, contenido no disponible, cuota, fallos del servidor y respuestas inesperadas.

## Verificación

```sh
flutter analyze
flutter test
```

Las pruebas usan respuestas controladas y un almacén Hive temporal. Cubren la búsqueda, la navegación adaptable, los fallos de red y la reapertura de favoritos sin conexión.

Las fuentes Manrope y Source Serif 4 se incluyen con sus [licencias OFL](assets/fonts/).
