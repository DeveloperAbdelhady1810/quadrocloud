<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class ServiceCatalogSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $services = [
            ['name' => 'استضافة ويب', 'description' => 'استضافة مواقع الويب والنطاقات', 'default_price' => 500],
            ['name' => 'دعم تقني شهري', 'description' => 'صيانة وإدارة الأنظمة شهرياً', 'default_price' => 2000],
            ['name' => 'تطوير تطبيق ويب', 'description' => 'تطوير تطبيق ويب مخصص', 'default_price' => 10000],
            ['name' => 'تطوير تطبيق موبايل', 'description' => 'تطبيق iOS وAndroid', 'default_price' => 15000],
            ['name' => 'نظام ERP', 'description' => 'نظام إدارة موارد المؤسسة', 'default_price' => 25000],
            ['name' => 'نظام LMS', 'description' => 'منصة التعلم الإلكتروني', 'default_price' => 12000],
            ['name' => 'SaaS اشتراك', 'description' => 'اشتراك في منتج SaaS', 'default_price' => 1000],
            ['name' => 'استشارات تقنية', 'description' => 'جلسات استشارية تقنية', 'default_price' => 3000],
        ];

        foreach ($services as $service) {
            \App\Models\ServiceCatalog::firstOrCreate(['name' => $service['name']], $service);
        }
    }
}
