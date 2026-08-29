import { IsString, Length, MinLength } from 'class-validator';

export class UpdateProfileDto {
  @IsString()
  @MinLength(3)
  name: string | null;

  @IsString()
  @MinLength(5)
  description: string | null;
}
