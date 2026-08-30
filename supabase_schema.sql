-- Free Map Review - Supabase Schema
-- Execute this in Supabase SQL Editor

-- Enable extensions
create extension if not exists postgis;
create extension if not exists "uuid-ossp";

-- Categories enum
create type category_type as enum ('vegan', 'healthcare', 'general');

-- Locations table
create table locations (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  description text,
  lat double precision not null,
  lng double precision not null,
  category category_type not null default 'general',
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  user_id uuid not null references auth.users(id) on delete cascade
);

-- Reviews table
create table reviews (
  id uuid primary key default uuid_generate_v4(),
  location_id uuid not null references locations(id) on delete cascade,
  rating integer not null check (rating >= 1 and rating <= 5),
  review_text text,
  category_detail text,
  images jsonb default '[]'::jsonb,
  is_anonymous boolean not null default true,
  created_at timestamptz not null default now()
);

-- Indexes
create index idx_locations_user_id on locations(user_id);
create index idx_locations_category on locations(category);
create index idx_reviews_location_id on reviews(location_id);
create index idx_reviews_created_at on reviews(created_at desc);

-- PostGIS geography index for radius queries
alter table locations add column geo_point geography(Point, 4326);
update locations set geo_point = st_setsrid(st_makepoint(lng, lat), 4326)::geography;
create index idx_locations_geo_point on locations using gist(geo_point);

-- Trigger to keep geo_point in sync
create or replace function update_geo_point()
returns trigger as $$
begin
  new.geo_point := st_setsrid(st_makepoint(new.lng, new.lat), 4326)::geography;
  return new;
end;
$$ language plpgsql;

create trigger trigger_update_geo_point
  before insert or update of lat, lng on locations
  for each row execute function update_geo_point();

-- Storage bucket for location images
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('location-images', 'location-images', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- Storage policies
create policy "Public read access"
  on storage.objects for select
  using (bucket_id = 'location-images');

create policy "Authenticated users can upload"
  on storage.objects for insert
  with check (
    bucket_id = 'location-images' and
    auth.uid() is not null
  );

-- RLS Policies for locations
alter table locations enable row level security;

create policy "Locations are viewable by everyone"
  on locations for select
  using (true);

create policy "Authenticated users can insert locations"
  on locations for insert
  with check (auth.uid() is not null and auth.uid() = user_id);

create policy "Users can update own locations"
  on locations for update
  using (auth.uid() = user_id);

create policy "Users can delete own locations"
  on locations for delete
  using (auth.uid() = user_id);

-- RLS Policies for reviews
alter table reviews enable row level security;

create policy "Reviews are viewable by everyone"
  on reviews for select
  using (true);

create policy "Authenticated users can insert reviews"
  on reviews for insert
  with check (
    auth.uid() is not null and
    exists (select 1 from locations where id = location_id)
  );

create policy "Users can update own reviews"
  on reviews for update
  using (
    auth.uid() is not null and
    exists (
      select 1 from locations l
      where l.id = reviews.location_id and l.user_id = auth.uid()
    )
  );

create policy "Users can delete own reviews"
  on reviews for delete
  using (
    auth.uid() is not null and
    exists (
      select 1 from locations l
      where l.id = reviews.location_id and l.user_id = auth.uid()
    )
  );
