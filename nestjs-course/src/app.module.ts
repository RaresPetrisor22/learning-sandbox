import { Module } from '@nestjs/common';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { ProfilesModule } from './profiles/profiles.module.js';

@Module({
  imports: [ProfilesModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
