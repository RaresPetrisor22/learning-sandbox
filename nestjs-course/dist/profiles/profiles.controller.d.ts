import { CreateProfileDto } from './dto/create-profile.dto.js';
import { UpdateProfileDto } from './dto/update-profile.dto.js';
export declare class ProfilesController {
    findAll(location: string): {
        location: string;
    }[];
    findOne(id: string): {
        id: string;
    };
    create(createProfileDto: CreateProfileDto): {
        name: string;
        description: string;
    };
    update(id: string, updateProfileDto: UpdateProfileDto): {
        name: string | null;
        description: string | null;
        id: string;
    };
    remove(id: string): void;
}
