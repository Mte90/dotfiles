<!-- This file is loaded on demand from frameworks/django/SKILL.md -->

## pgvector Semantic Search

Vector similarity search with PostgreSQL and Django.

### Setup

```bash
pip install pgvector sentence-transformers psycopg[binary]
```

```python
# Migration to enable extension
from pgvector.django import VectorExtension

class Migration(migrations.Migration):
    operations = [VectorExtension()]
```

### Model with Embeddings

```python
from django.db import models
from pgvector.django import VectorField, CosineDistance
from sentence_transformers import SentenceTransformer

T = SentenceTransformer("distiluse-base-multilingual-cased-v1")

class Item(models.Model):
    content = models.TextField()
    embedding = VectorField(dimensions=512, editable=False)
    
    def save(self, *args, **kwargs):
        self.embedding = T.encode(self.content)
        super().save(*args, **kwargs)
    
    @classmethod
    def search(cls, q, dmax=0.5):
        distance = CosineDistance("embedding", T.encode(q))
        return (
            cls.objects.alias(distance=distance)
            .filter(distance__lt=dmax)
            .order_by(distance)
        )

# Usage
results = Item.search("python tutorial")
```

### SQL Generated

```sql
SELECT * FROM items_item 
WHERE (embedding <=> '[vector]') < 0.5 
ORDER BY (embedding <=> '[vector]') ASC;
```

---


---

## GeneratedField (Django 5.0+)

Database-generated columns that are computed by the DB when source fields change.

### SQLite Examples

```python
# Mathematical calculation
class Rectangle(models.Model):
    base = models.FloatField()
    height = models.FloatField()
    area = models.GeneratedField(
        expression=F("base") * F("height"),
        output_field=models.FloatField(),
        db_persist=True,
    )

# Conditional status
class Order(models.Model):
    creation = models.DateTimeField()
    payment = models.DateTimeField(null=True)
    status = models.GeneratedField(
        expression=Case(
            When(payment__isnull=False, then=Value("paid")),
            default=Value("created"),
        ),
        output_field=models.TextField(),
    )

# Date truncation
class Event(models.Model):
    start = models.DateTimeField()
    start_date = models.GeneratedField(
        expression=TruncDate("start"),
        output_field=models.DateField(),
    )
```

### PostgreSQL Examples

```python
# JSON key extraction
class Package(models.Model):
    slug = models.CharField()
    data = models.JSONField()
    version = models.GeneratedField(
        expression=F("data__info__version"),
        output_field=models.CharField(),
    )

# Full-text search vector
from django.contrib.postgres.search import SearchVector, SearchVectorField

class Quote(models.Model):
    author = models.CharField()
    text = models.TextField()
    search = models.GeneratedField(
        expression=SearchVector("text", config="english"),
        output_field=SearchVectorField(),
    )

# Array length
from django.contrib.postgres.fields import ArrayField, ArrayLenTransform

class Landmark(models.Model):
    name = models.CharField()
    reviews = ArrayField(models.SmallIntegerField())
    count = models.GeneratedField(
        expression=ArrayLenTransform("reviews"),
        output_field=models.IntegerField(),
    )
```

**⚠️ Note**: PostgreSQL requires IMMUTABLE functions only. Use `||` operator instead of `Concat`.

---


---

## GeoDjango with Pillow and GPS

Build maps with automatic GPS extraction from photo EXIF data.

### Setup

```python
# settings.py
INSTALLED_APPS = ["django.contrib.gis", "markers"]

DATABASES = {
    "default": {
        "ENGINE": "django.contrib.gis.db.backends.spatialite",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}
```

### GPS Extraction from Images

```python
from PIL import Image
from PIL.ExifTags import GPS, IFD
from django.contrib.gis.geos import Point

def dms_to_dd(degrees, minutes, seconds, ref):
    REFS = {"N": 1, "S": -1, "E": 1, "W": -1}
    return (float(degrees) + float(minutes)/60 + float(seconds)/3600) * REFS.get(ref, 0)

def get_point(image):
    gpsinfo = Image.open(image).getexif().get_ifd(IFD.GPSInfo)
    longitude = dms_to_dd(*gpsinfo.get(GPS.GPSLongitude, (0,0,0)), gpsinfo.get(GPS.GPSLongitudeRef, "E"))
    latitude = dms_to_dd(*gpsinfo.get(GPS.GPSLatitude, (0,0,0)), gpsinfo.get(GPS.GPSLatitudeRef, "N"))
    return Point(longitude, latitude)
```

### Model with Auto-GPS

```python
class Marker(models.Model):
    name = models.CharField()
    location = models.PointField(blank=True)
    image = models.ImageField(upload_to="images/markers/")

    def save(self, *args, **kwargs):
        self.location = get_point(self.image)
        super().save(*args, **kwargs)
```

### Admin and GeoJSON

```python
from django.contrib.gis import admin

@admin.register(Marker)
class MarkerAdmin(admin.GISModelAdmin):
    list_display = ("name", "location", "image")

# Serialize to GeoJSON
from django.core.serializers import serialize
import json

geojson = json.loads(serialize("geojson", Marker.objects.all()))
```

---


---

## PostgreSQL Superpowers

### Full-Text Search

```python
from django.contrib.postgres.search import SearchQuery, SearchVector

# Simple search
results = Article.objects.annotate(
    search=SearchVector("title", "body")
).filter(search="django")

# With ranking
from django.contrib.postgres.search import SearchRank

results = Article.objects.annotate(
    rank=SearchRank(SearchVector("body"), SearchQuery("django"))
).order_by("-rank")
```

### Array Fields

```python
from django.contrib.postgres.fields import ArrayField

class Recipe(models.Model):
    name = models.CharField()
    tags = ArrayField(models.CharField(max_length=50))

# Query
Recipe.objects.filter(tags__contains=["vegan", "quick"])
Recipe.objects.filter(tags__overlap=["breakfast", "lunch"])
```

### Range Fields

```python
from django.contrib.postgres.fields import IntegerRangeField, DateRangeField

class Booking(models.Model):
    room = models.CharField()
    stay = DateRangeField()

# Overlap query
Booking.objects.filter(stay__overlap=[start_date, end_date])
```

### JSONB Operations

```python
class Product(models.Model):
    data = models.JSONField()

# Key existence
Product.objects.filter(data__has_key="specs")

# Path query
Product.objects.filter(data__specs__memory__gte=16)
```

---


